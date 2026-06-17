module bad_apple_top(
    input  wire        clk_50M,    // 系統 50MHz 時脈
    input  wire        rst_n,      // 系統復位 (Active Low)
    output wire [15:0] DOT_R,      // 點陣列資料輸出
    output wire [3:0]  DOT_C,      // 點陣列掃描控制 (4-to-16解碼器)
	 output wire [2:0]  SEL,
	 output wire [0:7]  Seg,
	 output wire [11:0] LEDs
);

    // 系統總畫格數
    parameter TOTAL_FRAMES = 12'd1753;

    // 內部連接線 (全局畫格進度)
    wire [11:0] frame_cnt;
	 wire [7:0] dp_ctrl = 8'b00000100;
	 assign LEDs = 12'b000000000000;

    // 1. 實例化：時脈與同步中心
    system_timing #(
        .MAX_FRAME(TOTAL_FRAMES)
    ) u_timing (
        .clk_50M    (clk_50M),
        .rst_n      (rst_n),
        .frame_cnt  (frame_cnt)
    );

    // 2. 實例化：2-bit 灰階影像引擎
    video_engine u_video (
        .clk_50M    (clk_50M),
        .rst_n      (rst_n),
        .frame_cnt  (frame_cnt),
        .DOT_R      (DOT_R),
        .DOT_C      (DOT_C)
    );
	 
	 BCD_7_segment_engine bcd_engine(
        .clk_50M    (clk_50M), 
		  .rst_n       (rst_n),
        .dp_ctrl     (dp_ctrl),
        .SEL         (SEL),
        .Seg         (Seg)
	);

endmodule
