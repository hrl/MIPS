`ifndef _defines
`define _defines

//// ALU
// ALU OP
`define ALU_OP_ADD  4'b0000 // 0
`define ALU_OP_SUB  4'b0001 // 1
`define ALU_OP_SLL  4'b0010 // 2
`define ALU_OP_SRA  4'b0011 // 3
`define ALU_OP_SRL  4'b0100 // 4
`define ALU_OP_OR   4'b0101 // 5
`define ALU_OP_NOR  4'b0110 // 6
`define ALU_OP_AND  4'b0111 // 7
`define ALU_OP_NAND 4'b1000 // 8
`define ALU_OP_XOR  4'b1001 // 9
`define ALU_OP_NXOR 4'b1010 // a
`define ALU_OP_LST  4'b1011 // b
`define ALU_OP_LSTU 4'b1100 // c
`define ALU_OP_NOP  4'b1111 // d

`endif
