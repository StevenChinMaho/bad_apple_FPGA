import cv2
import numpy as np
import os

# ==========================================
# 1. 使用者參數設定區 (請在此處自由修改)
# ==========================================
INPUT_VIDEO = 'bad_apple.mp4'       # 輸入影片檔名
OUTPUT_MIF = 'bad_apple_video.mif'  # 輸出的 MIF 檔名

# (一) 輸出畫面解析度
TARGET_WIDTH = 16
TARGET_HEIGHT = 16

# (二) 灰階位元深度 (2-bit 灰階代表 4 階亮度)
BIT_DEPTH = 2

# (三) 調整模式 (0: 裁切, 1: 拉伸, 2: 填滿黑邊)
# 裁切：保證無黑邊但會損失畫面；拉伸：會變形；填滿：維持比例但有黑邊
RESIZE_MODE = 0 

# (四) 目標 FPS
TARGET_FPS = 8.0

# (五) 旋轉 (0: 不轉, 1: 順時針90度, 2: 180度, 3: 順時針270度)
ROTATION_MODE = 1

# (六) 左右鏡像
FLIP_H = False

# (七) 上下鏡像
FLIP_V = False

# (八) 灰階反轉 (False: 黑底白影, True: 白底黑影)
INVERT_COLOR = True

# ==========================================
# 2. 核心處理類別
# ==========================================
class VideoToMifConverter:
    def __init__(self):
        self.levels = 2 ** BIT_DEPTH  # 亮度階層數 (2-bit = 4階)
        
    def process_frame(self, frame):
        # 1. 轉為灰階
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # 2. 旋轉處理 (必須在 Resize 之前做，因為會影響長寬比)
        if ROTATION_MODE == 1:
            gray = cv2.rotate(gray, cv2.ROTATE_90_CLOCKWISE)
        elif ROTATION_MODE == 2:
            gray = cv2.rotate(gray, cv2.ROTATE_180)
        elif ROTATION_MODE == 3:
            gray = cv2.rotate(gray, cv2.ROTATE_90_COUNTERCLOCKWISE)
            
        # 3. 鏡像翻轉
        if FLIP_H:
            gray = cv2.flip(gray, 1) # 1 代表水平翻轉
        if FLIP_V:
            gray = cv2.flip(gray, 0) # 0 代表垂直翻轉
            
        # 4. 畫面調整 (Resize)
        ih, iw = gray.shape
        tw, th = TARGET_WIDTH, TARGET_HEIGHT
        
        if RESIZE_MODE == 0:
            # [0. 裁切 Crop]
            aspect_in = iw / ih
            aspect_target = tw / th
            if aspect_in > aspect_target:
                # 原始影片太寬，裁掉左右
                new_w = int(ih * aspect_target)
                x_offset = (iw - new_w) // 2
                gray = gray[:, x_offset:x_offset+new_w]
            else:
                # 原始影片太高，裁掉上下
                new_h = int(iw / aspect_target)
                y_offset = (ih - new_h) // 2
                gray = gray[y_offset:y_offset+new_h, :]
            resized = cv2.resize(gray, (tw, th), interpolation=cv2.INTER_AREA)
            
        elif RESIZE_MODE == 1:
            # [1. 拉伸 Stretch]
            resized = cv2.resize(gray, (tw, th), interpolation=cv2.INTER_AREA)
            
        else:
            # [2. 填滿 Pad]
            aspect_in = iw / ih
            aspect_target = tw / th
            if aspect_in > aspect_target:
                # 配合寬度，高度縮小補黑邊
                scale = tw / iw
                new_w = tw
                new_h = int(ih * scale)
            else:
                # 配合高度，寬度縮小補黑邊
                scale = th / ih
                new_w = int(iw * scale)
                new_h = th
                
            scaled = cv2.resize(gray, (new_w, new_h), interpolation=cv2.INTER_AREA)
            # 建立全黑畫布
            resized = np.zeros((th, tw), dtype=np.uint8)
            y_off = (th - new_h) // 2
            x_off = (tw - new_w) // 2
            # 將縮小後的影像貼到正中間
            resized[y_off:y_off+new_h, x_off:x_off+new_w] = scaled

        # 5. 反轉顏色
        if INVERT_COLOR:
            resized = 255 - resized

        # 6. 位元深度量化 (Quantization)
        # 假設 2-bit (4階), 256 // 4 = 64. 像素值除以 64 即為 0, 1, 2, 3
        quantized = resized // (256 // self.levels)
        # 防止極端值越界 (255 // 64 = 3，安全)

        # 7. 轉換為 FPGA 二進位字串 (將 16 個點的資料拼成一列)
        row_strs = []
        format_str = f"0{BIT_DEPTH}b" # 如果 BIT_DEPTH 是 2，這會變成 '02b' (格式化為 2 位元二進位)
        for row in quantized:
            # 將該列所有像素轉為二進位字串並合併
            row_str = "".join([format(pixel, format_str) for pixel in row])
            row_strs.append(row_str)
            
        return row_strs

    def run(self):
        if not os.path.exists(INPUT_VIDEO):
            print(f"找不到影片檔案: {INPUT_VIDEO}")
            return

        cap = cv2.VideoCapture(INPUT_VIDEO)
        
        # 影片時間控制變數
        frame_interval_ms = 1000.0 / TARGET_FPS
        next_capture_time_ms = 0.0
        
        mif_data_lines = []
        extracted_frames = 0
        
        print("開始處理影片，請稍候...")
        print(f"設定: {TARGET_WIDTH}x{TARGET_HEIGHT}, {BIT_DEPTH}-bit 灰階, FPS: {TARGET_FPS}")
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break # 影片結束
                
            current_time_ms = cap.get(cv2.CAP_PROP_POS_MSEC)
            
            # 利用時間戳比對來達到絕對的 FPS 穩定
            if current_time_ms >= next_capture_time_ms:
                rows_data = self.process_frame(frame)
                mif_data_lines.extend(rows_data)
                
                extracted_frames += 1
                next_capture_time_ms += frame_interval_ms
                
                if extracted_frames % 500 == 0:
                    print(f"已處理 {extracted_frames} 幀...")

        cap.release()
        
        # 寫出 MIF 檔案
        total_depth = len(mif_data_lines)
        total_width_bits = TARGET_WIDTH * BIT_DEPTH
        
        print(f"\n處理完成！總計產生 {extracted_frames} 幀，MIF 總深度: {total_depth}")
        print(f"開始生成 {OUTPUT_MIF}...")
        
        with open(OUTPUT_MIF, 'w') as f:
            f.write(f"DEPTH = {total_depth};\n")
            f.write(f"WIDTH = {total_width_bits};\n")
            f.write("ADDRESS_RADIX = UNS;\n")
            f.write("DATA_RADIX = BIN;\n")
            f.write("CONTENT BEGIN\n")
            
            for i, row_str in enumerate(mif_data_lines):
                f.write(f"\t{i}\t:\t{row_str};\n")
                
            f.write("END;\n")
            
        print("MIF 檔案生成完畢！")

# ==========================================
# 3. 程式執行入口
# ==========================================
if __name__ == "__main__":
    converter = VideoToMifConverter()
    converter.run()