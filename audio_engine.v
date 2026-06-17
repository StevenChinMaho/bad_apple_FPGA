module audio_engine(
    input  wire        clk_50M,
    input  wire        rst_n,
    input  wire [11:0] frame_cnt,
    output reg         buzzer_out
);

    wire [7:0] current_note;

    // 呼叫你在 Quartus IP Catalog 建立的音符 ROM
    // (寬度 8-bit，深度與總畫格數相同)
    audio_rom u_audio_rom (
        .address (frame_cnt),
        .clock   (clk_50M),
        .q       (current_note)
    );

    // --- 蜂鳴器頻率合成器 ---
    reg [19:0] target_freq_cnt;
    reg [19:0] buzzer_cnt;

    // 音符代碼對應頻率的 LUT (Look-Up Table)
    // 這裡示範中央 C (C4) 到 C5 的基本對應，你可以依據 MIDI 檔擴充
    always @(*) begin
        case (current_note)
            8'd0:  target_freq_cnt = 20'd0;     // 休止符 (無聲)
            8'd60: target_freq_cnt = 20'd95555; // C4 (261.6 Hz) -> 50M / 261.6 / 2
            8'd62: target_freq_cnt = 20'd85132; // D4 (293.6 Hz)
            8'd64: target_freq_cnt = 20'd75842; // E4 (329.6 Hz)
            8'd65: target_freq_cnt = 20'd71586; // F4 (349.2 Hz)
            8'd67: target_freq_cnt = 20'd63776; // G4 (392.0 Hz)
            8'd69: target_freq_cnt = 20'd56818; // A4 (440.0 Hz)
            8'd71: target_freq_cnt = 20'd50620; // B4 (493.8 Hz)
            8'd72: target_freq_cnt = 20'd47778; // C5 (523.2 Hz)
            default: target_freq_cnt = 20'd0;   // 預設無聲
        endcase
    end

    // 產生對應頻率的方波 (PWM 50% 占空比)
    always @(posedge clk_50M or negedge rst_n) begin
        if (!rst_n) begin
            buzzer_cnt <= 20'd0;
            buzzer_out <= 1'b0;
        end else if (target_freq_cnt == 20'd0) begin
            buzzer_cnt <= 20'd0;
            buzzer_out <= 1'b0; // 休止符時保持低電位
        end else if (buzzer_cnt >= target_freq_cnt) begin
            buzzer_cnt <= 20'd0;
            buzzer_out <= ~buzzer_out; // 翻轉電位產生方波
        end else begin
            buzzer_cnt <= buzzer_cnt + 1'b1;
        end
    end

endmodule
