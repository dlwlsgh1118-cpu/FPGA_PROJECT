`timescale 1ns/1ps

module tb_aes_ctr();
    reg clk, reset, start;
    reg [127:0] key;
    reg [63:0]  nonce;
    reg [127:0] p_text;
    wire [127:0] c_text;
    wire ready;

    wire [127:0] fpga_aes_in = uut.aes_unit.in;
    wire [63:0]  fpga_ctr    = uut.ctr;
    wire [127:0] fpga_state  = uut.aes_unit.state;
    wire [3:0]   fpga_round  = uut.aes_unit.round;

    aes_ctr_top uut (
        .clk      (clk),
        .reset    (reset),
        .start    (start),
        .key      (key),
        .nonce    (nonce),
        .p_text   (p_text),
        .valid_len(5'd16),
        .c_text   (c_text),
        .ready    (ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk)
        $display("CLK | round=%0d | state=%h", fpga_round, fpga_state);

    initial begin
        clk = 0; reset = 1; start = 0;
        key    = 128'h000102030405060708090a0b0c0d0e0f;
        nonce  = 64'hdeadbeefdeadbeef;
        p_text = 128'h000000000000000000000000000004d2;

        #20 reset = 0;
        #20 start = 1;
        @(posedge clk);
        $display("AES in: %h | ctr: %h", fpga_aes_in, fpga_ctr);
        #10 start = 0;

        wait(ready);
        $display("c_text: %h", c_text);
        $display("기대값: b876aff70a8c706999511b08ad62d5b4");

        #100 $stop;
    end
endmodule
