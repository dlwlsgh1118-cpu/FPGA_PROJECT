// AES 관련 상수 정의
`define AES_128      128
`define KEY_128      128
`define ROUNDS_10     10

// 상태 정의 (FSM용)
`define ST_IDLE      3'b000
`define ST_WAIT      3'b001
`define ST_AES_RUN   3'b010
`define ST_XOR       3'b011
`define ST_DONE      3'b100