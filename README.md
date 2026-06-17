# Bad Apple!! but it's a FPGA

## 專案介紹

此專案使用 Quartus Prime 15.1 Lite Edition 環境開發，並在 SOPC-EP4CE40 EDA/SOPC 系統綜合開發平台 實驗箱運行。

此專案使用 Python 腳本將影片檔以 **每秒 8 張的頻率 (8FPS)** 轉換成 2-bit 深度灰階、 16x16 二進位資料，並轉換成可寫入 M9K SRAM 的 `mif` 檔，作為影片資料的 ROM 來讀取。最後將讀取的資料以特定方式掃描顯示在 16x16 LED 陣列。

理論上此 Python 腳本能夠轉換任意影片，但要注意資料容量是否能夠放進 SRAM，總幀數最好不要超過 1800，避免資料過大導致編譯失敗。另外也需要修改 ROM 的資料深度與 Verilog 內讀取與掃描的參數。

[展示影片](https://youtu.be/A1Gat5pI8HI)

## 安裝方式

1. 運行 `py video_to_mif.py` 生成 `mif` 檔案。
2. 在 Quartus 中開啟並編譯專案。
3. 使用 Programmer 將 `output_files/bad_apple.sof` 寫入 FPGA。
4. 享受你的壞蘋果。

## 參考

[國立台南大學: SOPC-EP4CE40 EDA/SOPC 系統綜合開發平臺使用手冊](https://csd.nutn.edu.tw/DSE/SOPC-EP4CE4.pdf)
