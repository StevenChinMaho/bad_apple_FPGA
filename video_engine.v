module video_engine(
    input  wire        clk_50M,
    input  wire        rst_n,
    input  wire [11:0] frame_cnt,  // 來自 system_timing (8Hz更新)
    output wire [15:0] DOT_R,
    output wire [3:0]  DOT_C
);

    // 1. 產生極高速的 PWM 掃描時脈 (例如 100kHz)
    // 為了讓灰階不閃爍，掃描速度必須非常快
    reg [8:0] scan_div;
    wire fast_scan_tick = (scan_div == 9'd499); // 50M / 500 = 100kHz

    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) scan_div <= 9'd0;
        else scan_div <= fast_scan_tick ? 9'd0 : scan_div + 1'b1;
    end

    // 2. 雙層計數器：掃描列 (0~15) 與 PWM 週期 (0~2)
    reg [3:0] scan_cnt; // 控制 4-16 解碼器
    reg [1:0] pwm_cnt;  // 控制佔空比 (0, 1, 2)

    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= 4'd0;
            pwm_cnt  <= 2'd0;
        end else if (fast_scan_tick) begin
            if (scan_cnt == 4'd15) begin
                scan_cnt <= 4'd0;
                // 掃完 16 列後，切換下一個 PWM 週期
                if (pwm_cnt == 2'd2) pwm_cnt <= 2'd0;
                else pwm_cnt <= pwm_cnt + 1'b1;
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    assign DOT_C = scan_cnt;

    // 3. 讀取 ROM 資料 (現在是 32 bits 寬度)
    wire [31:0] rom_data; 
    wire [15:0] rom_addr = {frame_cnt, scan_cnt}; // 地址拼接不變！

    video_rom u_video_rom (
        .address ( rom_addr ),
        .clock   ( clk_50M  ),
        .q       ( rom_data )
    );

    // 4. 核心解碼：將 32 bits 資料拆解給 16 顆 LED，並與 PWM 計數器比較
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pwm_decode
            // 取出對應的 2-bit 像素值
            // 當 i=0 時，取 [1:0]；當 i=1 時，取 [3:2]...
            wire [1:0] pixel_val = rom_data[i*2+1 : i*2];
            
            // PWM 比較邏輯：只要像素值大於當前的 PWM 週期就點亮
            assign DOT_R[i] = (pixel_val > pwm_cnt) ? 1'b1 : 1'b0;
        end
    endgenerate

endmodule
