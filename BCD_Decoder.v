module BCD_Decoder(
	output reg [0:7] Seg,
	input [3:0] K,
	input dp
);
	
	always @(*) begin
		case(K)
			4'b0000: Seg = { 7'b1111110, dp };
			4'b0001: Seg = { 7'b0110000, dp };
			4'b0010: Seg = { 7'b1101101, dp };
			4'b0011: Seg = { 7'b1111001, dp };
			4'b0100: Seg = { 7'b0110011, dp };
			4'b0101: Seg = { 7'b1011011, dp };
			4'b0110: Seg = { 7'b1011111, dp };
			4'b0111: Seg = { 7'b1110000, dp };
			4'b1000: Seg = { 7'b1111111, dp };
			4'b1001: Seg = { 7'b1111011, dp }; 
			4'b1010: Seg = { 7'b1110111, dp };	// A
			4'b1011: Seg = { 7'b0011111, dp };  // b
			4'b1100: Seg = { 7'b0001110, dp };  // L
			4'b1101: Seg = { 7'b0111101, dp };  // d
			4'b1110: Seg = { 7'b1001111, dp };  // E
			4'b1111: Seg = { 7'b1100111, dp };  // P
			default: Seg = { 7'b0000000, dp };
		endcase
	end
	
endmodule
