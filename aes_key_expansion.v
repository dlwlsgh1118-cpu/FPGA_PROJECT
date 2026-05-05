`module aes_key_expansion (
    input  [127:0]  key,
    output [1407:0] full_keys
);
    wire [31:0] w[0:43];
    
    // 초기 키 배치 (Round 0)
    assign {w[0], w[1], w[2], w[3]} = key;

    // Rcon 상수 정의 (표준 값)
    wire [31:0] rcon [1:10];
    assign rcon[1] = 32'h01000000; assign rcon[2] = 32'h02000000;
    assign rcon[3] = 32'h04000000; assign rcon[4] = 32'h08000000;
    assign rcon[5] = 32'h10000000; assign rcon[6] = 32'h20000000;
    assign rcon[7] = 32'h40000000; assign rcon[8] = 32'h80000000;
    assign rcon[9] = 32'h1b000000; assign rcon[10] = 32'h36000000;

    genvar i;
    generate
        for (i = 4; i < 44; i = i + 1) begin : key_gen
            if (i % 4 == 0) begin : special_case
                // 1. RotWord + SubWord (S-Box 사용)
                wire [31:0] rot_word = {w[i-1][23:0], w[i-1][31:24]};
                wire [7:0] s0, s1, s2, s3;
                
                aes_sbox sb0 (.in(rot_word[31:24]), .out(s0));
                aes_sbox sb1 (.in(rot_word[23:16]), .out(s1));
                aes_sbox sb2 (.in(rot_word[15:8]),  .out(s2));
                aes_sbox sb3 (.in(rot_word[7:0]),   .out(s3));
                
                // 2. XOR with Rcon
                assign w[i] = w[i-4] ^ {s0, s1, s2, s3} ^ rcon[i/4];
            end else begin : normal_case
                assign w[i] = w[i-4] ^ w[i-1];
            end
        end
    endgenerate

    // 11개 라운드 키(0~10)를 한 줄로 합체
    assign full_keys = {w[43], w[42], w[41], w[40], w[39], w[38], w[37], w[36], w[35], w[34], 
                        w[33], w[32], w[31], w[30], w[29], w[28], w[27], w[26], w[25], w[24], 
                        w[23], w[22], w[21], w[20], w[19], w[18], w[17], w[16], w[15], w[14], 
                        w[13], w[12], w[11], w[10], w[9], w[8], w[7], w[6], w[5], w[4], 
                        w[3], w[2], w[1], w[0]};
endmodule