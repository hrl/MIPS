`ifndef _defines
`define _defines

//// DEBUG
//`define _DEBUG_MODE_CPU
//`define _DEBUG_MODE_CON
//`define _DEBUG_MODE_RAM

//`define _DEBUG_MODE_MASK_X_VALUE

//// INSTRUCTION SET
// RAW INS
`define INS_RAW_OPCODE 31:26
`define INS_RAW_RS     25:21
`define INS_RAW_RT     20:16
`define INS_RAW_RD     15:11
`define INS_RAW_SHAMT  10:6
`define INS_RAW_FUNCT   5:0
`define INS_RAW_IMME   15:0
`define INS_RAW_ADDR   25:0
`define INS_RAW_IMME_SIGN 15

// TYPE R
// opcode == 6'b000000
// match funct
`define INS_R_ADD     6'b100000
`define INS_R_ADDU    6'b100001
`define INS_R_AND     6'b100100
`define INS_R_SLL     6'b000000
`define INS_R_SRA     6'b000011
`define INS_R_SRL     6'b000010
`define INS_R_SUB     6'b100010
`define INS_R_OR      6'b100101
`define INS_R_NOR     6'b100111
`define INS_R_SLT     6'b101010
`define INS_R_SLTU    6'b101011
`define INS_R_JR      6'b001000
`define INS_R_SYSCALL 6'b001100

// TYPE I
// match opcode
`define INS_I_ADDI    6'b001000
`define INS_I_ADDIU   6'b001001
`define INS_I_ANDI    6'b001100
`define INS_I_ORI     6'b001101
`define INS_I_LW      6'b100011
`define INS_I_SW      6'b101011
`define INS_I_BEQ     6'b000100
`define INS_I_BNE     6'b000101
`define INS_I_SLTI    6'b001010

// TYPE J
// match opcode
`define INS_J_J       6'b000010
`define INS_J_JAL     6'b000011

// TYPE C
// coprocessor ins
// opcode == 6'b010000
// match rs
`define INS_C_MFC0    5'b00000
`define INS_C_MTC0    5'b00100
// eret here
// ...

//// !END INSTRUCTION SET


//// CONTROL
// PARSED INS
`define CON_LSB               0
`define CON_IMME_EXT        0:0
`define CON_PC_INC          2:1
`define CON_PC_JUMP         3:3
`define CON_REG_WRITE_EN    4:4
`define CON_REG_WRITE_DATA  6:5
`define CON_REG_WRITE_NUM   8:7
`define CON_REG_READ1_EN    9:9
`define CON_REG_READ1_NUM  10:10
`define CON_REG_READ2_EN   11:11
`define CON_REG_READ2_NUM  12:12
`define CON_ALU_OP         16:13
`define CON_ALU_A          17:17
`define CON_ALU_B          19:18
`define CON_ALU_BRANCH     20:20
`define CON_MEM_CS         21:21
`define CON_MEM_RD         22:22
`define CON_MSB            22

//// IMME
`define IMME_EXT_ZERO 1'b0
`define IMME_EXT_SIGN 1'b1

`ifdef _DEBUG_MODE_MASK_X_VALUE
`define IMME_EXT_X    1'b0
`else
`define IMME_EXT_X    1'bx
`endif

//// INS MEM
`define PROGRAM_FILE "program.txt"
`define EXCEPTION_FILE "program.txt"

//// DATA MEM
`define MEM_CS_DISABLE 1'b0
`define MEM_CS_ENABLE  1'b1
`define MEM_RD_WRITE 1'b0
`define MEM_RD_READ  1'b1

//// PC
`define PC_JUMP_IMME 1'b0
`define PC_JUMP_REG  1'b1

`ifdef _DEBUG_MODE_MASK_X_VALUE
`define PC_JUMP_X    1'b0
`else
`define PC_JUMP_X    1'bx
`endif

`define PC_INC_NORMAL 2'b00
`define PC_INC_BRANCH 2'b01
`define PC_INC_JUMP   2'b10
`define PC_INC_STOP   2'b11

`define PC_INC_STOP_OR_MASK 2'b11

`ifdef _DEBUG_MODE_MASK_X_VALUE
`define PC_INC_X      2'b00
`else
`define PC_INC_X      2'bxx
`endif

//// REG
`define REG_READ1_EN_F 1'b0
`define REG_READ1_EN_T 1'b1
`define REG_READ1_NUM_RT 1'b0
`define REG_READ1_NUM_RS 1'b1

`define REG_READ2_EN_F 1'b0
`define REG_READ2_EN_T 1'b1
`define REG_READ2_NUM_RT 1'b0
`define REG_READ2_NUM_RS 1'b1

`define REG_WRITE_NUM_RT 2'b00
`define REG_WRITE_NUM_RD 2'b01
`define REG_WRITE_NUM_31 2'b10

`define REG_WRITE_DATA_ALU 2'b00
`define REG_WRITE_DATA_DM  2'b01
`define REG_WRITE_DATA_PC  2'b10

`ifdef _DEBUG_MODE_MASK_X_VALUE
`define REG_READ1_NUM_X  1'b0
`define REG_READ2_NUM_X  1'b0
`define REG_WRITE_NUM_X  2'b00
`define REG_WRITE_DATA_X 2'b00
`else
`define REG_READ1_NUM_X  1'bx
`define REG_READ2_NUM_X  1'bx
`define REG_WRITE_NUM_X  2'bxx
`define REG_WRITE_DATA_X 2'bxx
`endif

`define REG_WRITE_EN_F  1'b0
`define REG_WRITE_EN_T  1'b1

//// ALU
// ALU CONTROL
`define ALU_A_REG  1'b0
`define ALU_A_IMME 1'b1

`define ALU_B_REG   2'b00
`define ALU_B_IMME  2'b01
`define ALU_B_SHAMT 2'b10

`define ALU_BRANCH_BEQ 1'b0
`define ALU_BRANCH_BNE 1'b1

`ifdef _DEBUG_MODE_MASK_X_VALUE
`define ALU_A_X      1'b0
`define ALU_B_X      2'b00
`define ALU_BRANCH_X 1'b0
`else
`define ALU_A_X      1'bx
`define ALU_B_X      2'bxx
`define ALU_BRANCH_X 1'bx
`endif

// ALU OP
`define ALU_OP_ADD  4'b0000 /* 0 */
`define ALU_OP_SUB  4'b0001 /* 1 */
`define ALU_OP_SLL  4'b0010 /* 2 */
`define ALU_OP_SRA  4'b0011 /* 3 */
`define ALU_OP_SRL  4'b0100 /* 4 */
`define ALU_OP_OR   4'b0101 /* 5 */
`define ALU_OP_NOR  4'b0110 /* 6 */
`define ALU_OP_AND  4'b0111 /* 7 */
`define ALU_OP_NAND 4'b1000 /* 8 */
`define ALU_OP_XOR  4'b1001 /* 9 */
`define ALU_OP_NXOR 4'b1010 /* a */
`define ALU_OP_LST  4'b1011 /* b */
`define ALU_OP_LSTU 4'b1100 /* c */
`define ALU_OP_NOP  4'b1111 /* f */

`ifdef _DEBUG_MODE_MASK_X_VALUE
`define ALU_OP_X    4'b0101 /* 5 */
`else
`define ALU_OP_X    4'bxxxx
`endif

//// PIPELINE
// CON
`define CON_NOP {`MEM_RD_READ, `MEM_CS_DISABLE, `ALU_BRANCH_X, `ALU_B_X, `ALU_A_X, `ALU_OP_X, `REG_READ2_NUM_X, `REG_READ2_EN_F, `REG_READ1_NUM_X, `REG_READ1_EN_F, `REG_WRITE_NUM_X, `REG_WRITE_DATA_X, `REG_WRITE_EN_F, `PC_JUMP_X, `PC_INC_NORMAL, `IMME_EXT_X};

// HAZARD
`define HAZARD_STALL_IF  4
`define HAZARD_STALL_ID  3
`define HAZARD_STALL_EX  2
`define HAZARD_STALL_MEM 1
`define HAZARD_STALL_WB  0

`define HAZARD_FLUSH_IF  4
`define HAZARD_FLUSH_ID  3
`define HAZARD_FLUSH_EX  2
`define HAZARD_FLUSH_MEM 1
`define HAZARD_FLUSH_WB  0


`endif
