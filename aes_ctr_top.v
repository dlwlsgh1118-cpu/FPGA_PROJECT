module aes_ctr_top (
    input  clk,
    input  reset,
    input  start,
    input  [127:0] key,
    input  [63:0]  nonce,
    input  [127:0] p_text,
    input  [4:0]   valid_len,
    output [127:0] c_text,
    output ready
);
    reg  [63:0]  ctr;
    wire [1407:0] full_keys;
    wire [127:0] key_stream;
    wire aes_done;

    aes_key_expansion key_unit (
        .key(key),
        .full_keys(full_keys)
    );

    aes_core aes_unit (
        .clk      (clk),
        .reset    (reset),
        .start    (start),
        .full_keys(full_keys),
        .in       ({nonce, ctr}),
        .out      (key_stream),
        .done     (aes_done)
    );

    assign c_text = p_text ^ key_stream;
    assign ready  = aes_done;

    always @(posedge clk or posedge reset) begin
        if (reset)         ctr <= 64'h0;
        else if (aes_done) ctr <= ctr + 1;
    end
endmodule
