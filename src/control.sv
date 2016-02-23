`ifndef _control
`define _control

`include "defines.vh"

module control(
    input [31:0] ins,
    //// parsed ins data
    output [`CON_MSB:`CON_LSB] controls
    );
    reg [`CON_MSB:`CON_LSB] controls_reg;
    assign controls = controls_reg;
    // controls =
    // {MEM_RD, MEM_CS, ALU_BRANCH, ALU_B, ALU_A, ALU_OP, REG_READ2_NUM, REG_READ1_NUM, REG_WRITE_NUM, REG_WRITE_DATA, REG_WRITE_EN, PC_INC, IMME_EXT}
    //      19      18          17  16 15     14  13  10              9              8  7           6  5            4             3  2    1         0
    always_comb begin
        // default NOP (MEM_CS_DISABLE, REG_WRITE_EN_F)
        controls_reg = {`MEM_RD_READ, `MEM_CS_DISABLE, `ALU_BRANCH_BEQ, `ALU_B_REG, `ALU_A_REG, `ALU_OP_OR, `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_F, `PC_INC_NORMAL, `IMME_EXT_ZERO};
        // parse ins
        if (ins[`INS_RAW_OPCODE] == 6'b000000) begin
            // TYPE R
            case (ins[`INS_RAW_FUNCT])
                // TYPE R
                `INS_R_ADD: controls_reg = {`MEM_RD_READ, `MEM_CS_DISABLE, `ALU_BRANCH_BEQ, `ALU_B_REG, `ALU_A_REG, `ALU_OP_ADD, `REG_READ2_NUM_RT, `REG_READ1_NUM_RS, `REG_WRITE_NUM_RD, `REG_WRITE_DATA_ALU, `REG_WRITE_EN_T, `PC_INC_NORMAL, `IMME_EXT_ZERO};
                // default:
            endcase
        end else begin
            // TYPE I/J/C
            case (ins[`INS_RAW_OPCODE])
                // TYPE I
                // TYPE J
                // TYPE C
                // NOP
                // default:
            endcase
        end

        `ifdef _DEBUG_MODE
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
