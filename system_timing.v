module system_timing #(
    parameter MAX_FRAME = 12'd1753
)(
    input  wire        clk_50M,
    input  wire        rst_n,
    output reg  [11:0] frame_cnt   // 全局畫格計數器
);

    reg [22:0] frame_div;
    
    // 產生 8Hz 畫格脈衝 (50M / 6250000 = 8Hz，每秒播 8 幀)
    wire frame_tick = (frame_div == 23'd6249999); 

    // 除頻計數邏輯
    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            frame_div <= 23'd0;
        end else begin
            frame_div <= frame_tick ? 23'd0 : frame_div + 1'b1;
        end
    end

    // 全局畫格計數邏輯
    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            frame_cnt <= 12'd0;
        end else if (frame_tick) begin
            if (frame_cnt >= MAX_FRAME - 1)
                frame_cnt <= 12'd0; // 播完最後一幀就重頭開始
            else
                frame_cnt <= frame_cnt + 1'b1;
        end
    end

endmodule
