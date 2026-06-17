module BCD_7_segment_engine(
    output reg [2:0] SEL,
    output [0:7] Seg,
    input clk_50M, rst_n,
    input [7:0] dp_ctrl
);
    reg [3:0] current_bcd;
    reg current_dp;
    
	 reg [8:0] scan_div;
    wire fast_scan_tick = (scan_div == 9'd499); // 50M / 500 = 100kHz

    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) scan_div <= 9'd0;
        else scan_div <= fast_scan_tick ? 9'd0 : scan_div + 1'b1;
    end
	 
    // 0 ~ 5 circulation
    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            SEL <= 3'd7;
        end 
        else if (fast_scan_tick) begin
            if (SEL >= 3'd7 || SEL < 3'd0) begin	// when circulating, make sure SEL is between 0 and 7
                SEL <= 3'd0;
            end else begin
                SEL <= SEL + 1;
            end
        end 
    end

    // MUX
    always @(*) begin
        current_dp = dp_ctrl[SEL];
        case(SEL)
            3'd0: current_bcd = 4'b1011;
            3'd1: current_bcd = 4'b1010;
            3'd2: current_bcd = 4'b1101;
            3'd3: current_bcd = 4'b1010;
            3'd4: current_bcd = 4'b1111;
            3'd5: current_bcd = 4'b1111;
				3'd6: current_bcd = 4'b1100;
				3'd7: current_bcd = 4'b1110;
            default: current_bcd = 4'b0000;
        endcase
    end

    // BCD_Decoder
    BCD_Decoder dec(
        .Seg(Seg),
        .K(current_bcd),
        .dp(current_dp)
    );
endmodule
