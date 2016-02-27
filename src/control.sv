`ifndef _control
`define _control

`include "defines.vh"

module control(
    input [31:0] ins,
    //// parsed ins data
    output [`CON_MSB:`CON_LSB] controls,
    output reg eret
    );
    reg [`CON_MSB:`CON_LSB] controls_reg;
    assign controls = controls_reg;
    // controls =
    // {MEM_RD, MEM_CS, ALU_BRANCH, ALU_B, ALU_A, ALU_OP, REG_READ2_NUM, REG_READ1_NUM, REG_WRITE_NUM, REG_WRITE_DATA, REG_WRITE_EN, PC_JUMP, PC_INC, IMME_EXT}
    //      20      19          18  17 16     15  14  11             10              9  8           7  6            5             4        3  2    1         0
    always_comb begin
        eret = 1'b0;
        // default STOP (MEM_RD_READ, MEM_CS_DISABLE, REG_WRITE_EN_F, PC_INC_STOP, *_X)
        controls_reg = {`MEM_RD_READ, `MEM_CS_DISABLE, `ALU_BRANCH_X, `ALU_B_X, `ALU_A_X, `ALU_OP_OR, `REG_READ2_NUM_X, `REG_READ1_NUM_X, `REG_WRITE_NUM_X, `REG_WRITE_DATA_X, `REG_WRITE_EN_F, `PC_JUMP_X, `PC_INC_STOP, `IMME_EXT_X};
        // parse ins
        if (ins[`INS_RAW_OPCODE] == 6'b000000) begin
            // TYPE R
            case (ins[`INS_RAW_FUNCT])
                // TYPE R
                // diff:                                                                         |----------|              |----------|  |---------------|  |---------------|
                `INS_R_SLL:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_SHAMT, `ALU_A_REG, `ALU_OP_SLL , `REG_READ2_NUM_X , `REG_READ1_NUM_RT, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_SRA:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_SHAMT, `ALU_A_REG, `ALU_OP_SRA , `REG_READ2_NUM_X , `REG_READ1_NUM_RT, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_SRL:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_SHAMT, `ALU_A_REG, `ALU_OP_SRL , `REG_READ2_NUM_X , `REG_READ1_NUM_RT, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                // diff:                                                                                                   |----------|
                `INS_R_ADD:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_ADD , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_ADDU:    controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_ADD , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_AND:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_AND , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_SUB:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_SUB , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_OR:      controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_OR  , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_NOR:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_NOR , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_SLT:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_LST , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                `INS_R_SLTU:    controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_REG  , `ALU_A_REG, `ALU_OP_LSTU, `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                // Jump Register
                `INS_R_JR:      controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_REG , `PC_INC_JUMP  , `IMME_EXT_X   };
                // SYSCALL, use NOP (MEM_RD_READ, MEM_CS_DISABLE, REG_WRITE_EN_F, PC_INC_NORMAL, *_X)
                `INS_R_SYSCALL: controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                // default STOP (MEM_RD_READ, MEM_CS_DISABLE, REG_WRITE_EN_F, PC_INC_STOP, *_X)
                default:        controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_STOP  , `IMME_EXT_X   };
            endcase
        end else if (ins[`INS_RAW_OPCODE] == 6'b010000) begin
            // TYPE C
            if({ins[`INS_RAW_CO], ins[`INS_RAW_FUNCT]} == `INS_C_ERET) begin
                // ERET, use NOP (MEM_RD_READ, MEM_CS_DISABLE, REG_WRITE_EN_F, PC_INC_NORMAL, *_X)
                                controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_X   };
                                eret = 1'b1;
            end else begin
                case (ins[`INS_RAW_RS])
                // MFC0 here
                // MTC0 here
                // default STOP (MEM_RD_READ, MEM_CS_DISABLE, REG_WRITE_EN_F, PC_INC_STOP, *_X)
                default:        controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_STOP  , `IMME_EXT_X   };
                endcase
            end
        end else begin
            // TYPE I/J
            case (ins[`INS_RAW_OPCODE])
                // TYPE I
                // diff:                                                                                                   |----------|                                                                                                                                |------------|
                `INS_I_ADDI:    controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_ADD , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_RT, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_SIGN};
                `INS_I_ADDIU:   controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_ADD , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_RT, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_SIGN}; // !!!
                `INS_I_ANDI:    controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_AND , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_RT, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_ZERO};
                `INS_I_ORI:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_OR  , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_RT, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_ZERO};
                `INS_I_SLTI:    controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_LST , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_RT, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_SIGN};
                // diff:                        |-----------|  |-------------|                                                           |---------------|                     |---------------|  |-----------------|  |-------------|
                `INS_I_LW:      controls_reg = {`MEM_RD_READ , `MEM_CS_ENABLE , `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_ADD , `REG_READ2_NUM_X , `REG_READ1_NUM_RS, `REG_WRITE_NUM_RT, `REG_WRITE_DATA_DM , `REG_WRITE_EN_T, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_SIGN};
                `INS_I_SW:      controls_reg = {`MEM_RD_WRITE, `MEM_CS_ENABLE , `ALU_BRANCH_X  , `ALU_B_IMME , `ALU_A_REG, `ALU_OP_ADD , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_NORMAL, `IMME_EXT_SIGN};
                // diff:                                                        |-------------|
                `INS_I_BEQ:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_BEQ, `ALU_B_REG  , `ALU_A_REG, `ALU_OP_SUB , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_BRANCH, `IMME_EXT_SIGN};
                `INS_I_BNE:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_BNE, `ALU_B_REG  , `ALU_A_REG, `ALU_OP_SUB , `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_BRANCH, `IMME_EXT_SIGN};
                // TYPE J
                // diff:                                                                                                                                                       |---------------|  |-----------------|  |-------------|
                `INS_J_J:       controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_IMME, `PC_INC_JUMP  , `IMME_EXT_ZERO};
                `INS_J_JAL:     controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_31, `REG_WRITE_DATA_PC , `REG_WRITE_EN_T, `PC_JUMP_IMME, `PC_INC_JUMP  , `IMME_EXT_ZERO};
                // default STOP (MEM_RD_READ, MEM_CS_DISABLE, REG_WRITE_EN_F, PC_INC_STOP, *_X)
                default:        controls_reg = {`MEM_RD_READ , `MEM_CS_DISABLE, `ALU_BRANCH_X  , `ALU_B_X    , `ALU_A_X  , `ALU_OP_X   , `REG_READ2_NUM_X , `REG_READ1_NUM_X , `REG_WRITE_NUM_X , `REG_WRITE_DATA_X  , `REG_WRITE_EN_F, `PC_JUMP_X   , `PC_INC_STOP  , `IMME_EXT_X   };
            endcase
        end

        `ifdef _DEBUG_MODE_CON
            $display("");
            $display("ins: %b, %x", ins, ins);
            $display("    opcode: %b, %x", ins[`INS_RAW_OPCODE], ins[`INS_RAW_OPCODE]);
            $display("    rs: %b, %x", ins[`INS_RAW_RS], ins[`INS_RAW_RS]);
            $display("    rt: %b, %x", ins[`INS_RAW_RT], ins[`INS_RAW_RT]);
            $display("    rd: %b, %x", ins[`INS_RAW_RD], ins[`INS_RAW_RD]);
            $display("    shamt: %b, %x", ins[`INS_RAW_SHAMT], ins[`INS_RAW_SHAMT]);
            $display("    funct: %b, %x", ins[`INS_RAW_FUNCT], ins[`INS_RAW_FUNCT]);
            $display("    imme: %b, %x", ins[`INS_RAW_IMME], ins[`INS_RAW_IMME]);
            $display("    addr: %b, %x", ins[`INS_RAW_ADDR], ins[`INS_RAW_ADDR]);
            $display("controls: %b, %x", controls_reg, controls_reg);
            $display("    imme_ext      : %b, %x", controls_reg[`CON_IMME_EXT], controls_reg[`CON_IMME_EXT]);
            $display("    pc_inc        : %b, %x", controls_reg[`CON_PC_INC], controls_reg[`CON_PC_INC]);
            $display("    pc_jump       : %b, %x", controls_reg[`CON_PC_JUMP], controls_reg[`CON_PC_JUMP]);
            $display("    reg_write_en  : %b, %x", controls_reg[`CON_REG_WRITE_EN], controls_reg[`CON_REG_WRITE_EN]);
            $display("    reg_write_data: %b, %x", controls_reg[`CON_REG_WRITE_DATA], controls_reg[`CON_REG_WRITE_DATA]);
            $display("    reg_write_num : %b, %x", controls_reg[`CON_REG_WRITE_NUM], controls_reg[`CON_REG_WRITE_NUM]);
            $display("    reg_read1_num : %b, %x", controls_reg[`CON_REG_READ1_NUM], controls_reg[`CON_REG_READ1_NUM]);
            $display("    reg_read2_num : %b, %x", controls_reg[`CON_REG_READ2_NUM], controls_reg[`CON_REG_READ2_NUM]);
            $display("    alu_op        : %b, %x", controls_reg[`CON_ALU_OP], controls_reg[`CON_ALU_OP]);
            $display("    alu_a         : %b, %x", controls_reg[`CON_ALU_A], controls_reg[`CON_ALU_A]);
            $display("    alu_b         : %b, %x", controls_reg[`CON_ALU_B], controls_reg[`CON_ALU_B]);
            $display("    alu_branch    : %b, %x", controls_reg[`CON_ALU_BRANCH], controls_reg[`CON_ALU_BRANCH]);
            $display("    mem_cs        : %b, %x", controls_reg[`CON_MEM_CS], controls_reg[`CON_MEM_CS]);
            $display("    mem_rd        : %b, %x", controls_reg[`CON_MEM_RD], controls_reg[`CON_MEM_RD]);
        `endif
    end
    
endmodule

`endif
