module aes_core (
    input              clk,
    input              start,
    input      [1407:0] full_keys, // 128비트가 아니라 전체 키를 받음
    input      [127:0] in,
    output reg [127:0] out,
    output reg         done
);
    reg [127:0] state;
    reg [3:0]   round;
    wire [127:0] sub_bytes_out;
	 
	 // 현재 라운드에 맞는 키를 1408비트 뭉치에서 잘라옴
    // Round 0 = full_keys[0+:128], Round 1 = full_keys[128+:128] ...
    wire [127:0] current_round_key = full_keys[round * 128 +: 128];

    // 1. SubBytes (S-Box 16개)
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : sbox_gen
            aes_sbox sb (.in(state[k*8 +: 8]), .out(sub_bytes_out[k*8 +: 8]));
        end
    endgenerate

    // 2. ShiftRows 함수
    function [127:0] shift_rows(input [127:0] s);
        shift_rows = {s[127:120], s[95:88],   s[63:56],   s[31:24],
                      s[87:80],   s[55:48],   s[23:16],   s[119:112],
                      s[47:40],   s[15:8],    s[111:104], s[79:72],
                      s[7:0],     s[103:96],  s[71:64],   s[39:32]};
    endfunction

    // 3. MixColumns 함수 (GF(2^8) 연산 포함)
    function [7:0] xtime(input [7:0] b);
        xtime = {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    function [127:0] mix_columns(input [127:0] s);
        reg [7:0] c[0:3][0:3], n[0:3][0:3];
        integer i, j;
        begin
            for(i=0;i<4;i=i+1) for(j=0;j<4;j=j+1) c[i][j] = s[(i*4+j)*8 +: 8];
            for(j=0;j<4;j=j+1) begin
                n[0][j] = xtime(c[0][j]) ^ (xtime(c[1][j])^c[1][j]) ^ c[2][j] ^ c[3][j];
                n[1][j] = c[0][j] ^ xtime(c[1][j]) ^ (xtime(c[2][j])^c[2][j]) ^ c[3][j];
                n[2][j] = c[0][j] ^ c[1][j] ^ xtime(c[2][j]) ^ (xtime(c[3][j])^c[3][j]);
                n[3][j] = (xtime(c[0][j])^c[0][j]) ^ c[1][j] ^ c[2][j] ^ xtime(c[3][j]);
            end
            for(i=0;i<4;i=i+1) for(j=0;j<4;j=j+1) mix_columns[(i*4+j)*8 +: 8] = n[i][j];
        end
    endfunction

    // 4. 상태 제어
    always @(posedge clk) begin
        if (start) begin
            // 0라운드: 입력값과 0번 라운드 키 XOR
            state <= in ^ full_keys[0 +: 128]; 
            round <= 4'd1;
            done  <= 1'b0;
        end else if (round <= 10) begin
            if (round < 10)
                state <= mix_columns(shift_rows(sub_bytes_out)) ^ current_round_key;
            else
                state <= shift_rows(sub_bytes_out) ^ current_round_key;
            
            round <= round + 4'd1;
        end else begin
            out   <= state;
            done  <= 1'b1;
        end
    end
endmodule