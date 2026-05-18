module aes_key_expansion (
    input  [127:0]  key,
    output [1407:0] full_keys
);
    wire [31:0] w[0:43];

    assign {w[0], w[1], w[2], w[3]} = key;

    wire [31:0] rcon [1:10];
    assign rcon[1]  = 32'h01000000; assign rcon[2]  = 32'h02000000;
    assign rcon[3]  = 32'h04000000; assign rcon[4]  = 32'h08000000;
    assign rcon[5]  = 32'h10000000; assign rcon[6]  = 32'h20000000;
    assign rcon[7]  = 32'h40000000; assign rcon[8]  = 32'h80000000;
    assign rcon[9]  = 32'h1b000000; assign rcon[10] = 32'h36000000;

    genvar i;
    generate
        for (i = 4; i < 44; i = i + 1) begin : key_gen
            if (i % 4 == 0) begin : special_case
                wire [31:0] rot_word = {w[i-1][23:0], w[i-1][31:24]};
                wire [7:0] s0, s1, s2, s3;
                aes_sbox sb0 (.in(rot_word[31:24]), .out(s0));
                aes_sbox sb1 (.in(rot_word[23:16]), .out(s1));
                aes_sbox sb2 (.in(rot_word[15:8]),  .out(s2));
                aes_sbox sb3 (.in(rot_word[7:0]),   .out(s3));
                assign w[i] = w[i-4] ^ {s0, s1, s2, s3} ^ rcon[i/4];
            end else begin : normal_case
                assign w[i] = w[i-4] ^ w[i-1];
            end
        end
    endgenerate

    genvar r;
    generate
        for (r = 0; r < 11; r = r + 1) begin : key_bind
            assign full_keys[r*128 +: 128] = {w[r*4], w[r*4+1], w[r*4+2], w[r*4+3]};
        end
    endgenerate
endmodule
