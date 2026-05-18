module aes_core (
    input              clk,
    input              reset,
    input              start,
    input      [1407:0] full_keys,
    input      [127:0] in,
    output reg [127:0] out,
    output reg         done
);
    reg [127:0] state;
    reg [3:0]   round;
    wire [127:0] sub_bytes_out;

    reg [127:0] current_round_key;
    always @(*) begin
        case (round)
            4'd0:  current_round_key = full_keys[0    +: 128];
            4'd1:  current_round_key = full_keys[128  +: 128];
            4'd2:  current_round_key = full_keys[256  +: 128];
            4'd3:  current_round_key = full_keys[384  +: 128];
            4'd4:  current_round_key = full_keys[512  +: 128];
            4'd5:  current_round_key = full_keys[640  +: 128];
            4'd6:  current_round_key = full_keys[768  +: 128];
            4'd7:  current_round_key = full_keys[896  +: 128];
            4'd8:  current_round_key = full_keys[1024 +: 128];
            4'd9:  current_round_key = full_keys[1152 +: 128];
            4'd10: current_round_key = full_keys[1280 +: 128];
            default: current_round_key = 128'b0;
        endcase
    end

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : sbox_gen
            aes_sbox sb (
                .in (state[127-k*8 : 120-k*8]),
                .out(sub_bytes_out[127-k*8 : 120-k*8])
            );
        end
    endgenerate

    function [127:0] shift_rows(input [127:0] s);
        reg [7:0] b [0:15];
        begin
            {b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],
             b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]} = s;
            shift_rows = {b[0],  b[5],  b[10], b[15],
                          b[4],  b[9],  b[14], b[3],
                          b[8],  b[13], b[2],  b[7],
                          b[12], b[1],  b[6],  b[11]};
        end
    endfunction

    function [7:0] xtime(input [7:0] b);
        xtime = {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    function [127:0] mix_columns(input [127:0] s);
        reg [7:0] c[0:3][0:3], n[0:3][0:3];
        integer i, j;
        begin
            {c[0][0],c[1][0],c[2][0],c[3][0],
             c[0][1],c[1][1],c[2][1],c[3][1],
             c[0][2],c[1][2],c[2][2],c[3][2],
             c[0][3],c[1][3],c[2][3],c[3][3]} = s;
            for(j = 0; j < 4; j = j+1) begin
                n[0][j] = xtime(c[0][j]) ^ (xtime(c[1][j])^c[1][j]) ^ c[2][j] ^ c[3][j];
                n[1][j] = c[0][j] ^ xtime(c[1][j]) ^ (xtime(c[2][j])^c[2][j]) ^ c[3][j];
                n[2][j] = c[0][j] ^ c[1][j] ^ xtime(c[2][j]) ^ (xtime(c[3][j])^c[3][j]);
                n[3][j] = (xtime(c[0][j])^c[0][j]) ^ c[1][j] ^ c[2][j] ^ xtime(c[3][j]);
            end
            mix_columns = {n[0][0],n[1][0],n[2][0],n[3][0],
                           n[0][1],n[1][1],n[2][1],n[3][1],
                           n[0][2],n[1][2],n[2][2],n[3][2],
                           n[0][3],n[1][3],n[2][3],n[3][3]};
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state <= 128'b0;
            round <= 4'd0;
            done  <= 1'b0;
            out   <= 128'b0;
        end else if (start) begin
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
            out  <= state;
            done <= 1'b1;
        end
    end
endmodule
