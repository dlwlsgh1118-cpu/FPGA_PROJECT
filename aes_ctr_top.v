module aes_ctr_top (
    input clk,
    input reset,
    input start,
    input [127:0] key,
    input [63:0]  nonce,
    input [127:0] p_text,    // 원본 데이터 (128비트 미만일 경우 상위 비트부터 채워짐)
    input [4:0]   valid_len, // 유효 데이터 바이트 수 (1~16)
    output [127:0] c_text,
    output ready
);
    reg [63:0] ctr;
    wire [1407:0] full_keys;
    wire [127:0] key_stream;
    wire aes_done;
    
    // --- 패딩 로직 추가 ---
    reg [127:0] padded_p_text;
    wire [7:0] padding_val = 5'd16 - valid_len; // 부족한 바이트 수

    always @(*) begin
        if (valid_len >= 16) begin
            padded_p_text = p_text; // 16바이트 꽉 찼으면 패딩 없음
        end else begin
            // PKCS#7 패딩 구현: 유효 데이터 뒤를 padding_val로 채움
            // 예: 13바이트만 유효하면 나머지 3바이트를 03 03 03으로 채움
            padded_p_text = p_text;
            case (valid_len)
                5'd1:  padded_p_text[119:0] = {15{8'h0F}};
                5'd2:  padded_p_text[111:0] = {14{8'h0E}};
                5'd3:  padded_p_text[103:0] = {13{8'h0D}};
                5'd4:  padded_p_text[95:0]  = {12{8'h0C}};
                5'd5:  padded_p_text[87:0]  = {11{8'h0B}};
                5'd6:  padded_p_text[79:0]  = {10{8'h0A}};
                5'd7:  padded_p_text[71:0]  = {9{8'h09}};
                5'd8:  padded_p_text[63:0]  = {8{8'h08}};
                5'd9:  padded_p_text[55:0]  = {7{8'h07}};
                5'd10: padded_p_text[47:0]  = {6{8'h06}};
                5'd11: padded_p_text[39:0]  = {5{8'h05}};
                5'd12: padded_p_text[31:0]  = {4{8'h04}};
                5'd13: padded_p_text[23:0]  = {3{8'h03}};
                5'd14: padded_p_text[15:0]  = {2{8'h02}};
                5'd15: padded_p_text[7:0]   = 8'h01;
                default: padded_p_text = p_text;
            endcase
        end
    end
    // -----------------------

    // 1. 키 확장 모듈
    aes_key_expansion key_unit (
        .key(key), 
        .full_keys(full_keys)
    );

    // 2. AES Core
    aes_core aes_unit (
        .clk(clk),
        .start(start),
        .full_keys(full_keys),
        .in({nonce, ctr}),
        .out(key_stream),
        .done(aes_done)
    );

    // 패딩된 평문과 키 스트림을 XOR
    assign c_text = padded_p_text ^ key_stream;
    assign ready = aes_done;
    
    always @(posedge clk or posedge reset) begin
        if (reset) ctr <= 64'h0;
        else if (aes_done) ctr <= ctr + 1;  //암호화가 한 번 끝날 때마다 내부 카운터(ctr)를 1 증가
    end
endmodule