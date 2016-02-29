`ifndef _cpu_ex
`define _cpu_ex

`timescale 1ns / 1ps

`include "defines.vh"
`include "alu.sv"
`include "pc_calculator.sv"

module cpu_ex(
    input clk, // from global
    input clr, // from global
    input [31:0] current_pc, // from ID
    input [31:0] ins, // from ID
    input [`CON_MSB:`CON_LSB] controls, // from ID
    input [31:0] reg_read1_data, // from ID
    input [31:0] reg_read2_data, // from ID
    // latch signal
    output reg [31:0] current_pc_ex, // latch
    output reg [31:0] ins_ex, // latch
    output reg [`CON_MSB:`CON_LSB] controls_ex, // latch
    output reg [31:0] reg_read2_data_ex, // latch
    // stage EX output
    output reg [31:0] alu_result,
    output reg alu_zero,
    // pc change signal
    output [31:0] next_pc_realtime,
    output [1:0] pc_inc_realtime,
    // hazard detect signal
    output reg reg_write_en,
    output reg [4:0] reg_write_num,
    output [4:0] reg_write_num_realtime,
    // data redirect signal
    input [1:0] reg_read1_data_redirect,
    input [1:0] reg_read2_data_redirect,
    input [31:0] reg_write_data_mem,
    output [1:0] con_reg_write_data_realtime,
    output reg [31:0] reg_write_data, // result in last cycle
    // debug signal
    output reg [31:0] _syscall_display,
    output _debug_syscall,
    output [1:0] _debug_syscall_pc_inc_mask
    );
    assign _debug_syscall = _syscall;
    assign _debug_syscall_pc_inc_mask = _syscall_pc_inc_mask;

    wire [31:0] imme_extented;
    assign imme_extented = 
        (controls[`CON_IMME_EXT] == `IMME_EXT_ZERO) ? {16'h0, ins[`INS_RAW_IMME]} :
        (controls[`CON_IMME_EXT] == `IMME_EXT_SIGN) ? {(ins[`INS_RAW_IMME_SIGN] == 1'b0) ? 16'h0000: 16'hffff, ins[`INS_RAW_IMME]} :
        32'h0;
    wire [31:0] shamt_extented;
    assign shamt_extented = {27'h0, ins[`INS_RAW_SHAMT]};

    /* Arithmetic Logic Unit */
    //// VAR
    // INPUT
    // in control: controls
    wire [31:0] reg_read1_data_redirected;
    assign reg_read1_data_redirected =
        (reg_read1_data_redirect == `HAZARD_REDIRECT_EX) ? reg_write_data :
        (reg_read1_data_redirect == `HAZARD_REDIRECT_MEM) ? reg_write_data_mem :
        reg_read1_data;
    wire [31:0] reg_read2_data_redirected;
    assign reg_read2_data_redirected =
        (reg_read2_data_redirect == `HAZARD_REDIRECT_EX) ? reg_write_data :
        (reg_read2_data_redirect == `HAZARD_REDIRECT_MEM) ? reg_write_data_mem :
        reg_read2_data;
    wire [31:0] alu_a;
    assign alu_a =
        (controls[`CON_ALU_A] == `ALU_A_REG) ? reg_read1_data_redirected :
        (controls[`CON_ALU_A] == `ALU_A_IMME) ? imme_extented :
        32'h0;
    wire [31:0] alu_b;
    assign alu_b =
        (controls[`CON_ALU_B] == `ALU_B_REG) ? reg_read2_data_redirected :
        (controls[`CON_ALU_B] == `ALU_B_IMME) ? imme_extented :
        (controls[`CON_ALU_B] == `ALU_B_SHAMT) ? shamt_extented :
        32'h0;
    // OUTPUT
    wire [31:0] _alu_result;
    wire _alu_zero;
    //// MODULE
    alu main_alu(
        .op(controls[`CON_ALU_OP]),
        .a(alu_a),
        .b(alu_b),
        .result(_alu_result),
        .zero(_alu_zero)
    );

    /* Program Counter Calculator */
    //// VAR
    // INPUT
    // in global: clr
    // in control: controls
    // in pc_ff: current_pc
    wire alu_branch_result;
    assign alu_branch_result =
        (controls[`CON_ALU_BRANCH] == `ALU_BRANCH_BEQ) ? _alu_zero :
        (controls[`CON_ALU_BRANCH] == `ALU_BRANCH_BNE) ? !_alu_zero :
        1'h0;
    assign alu_branch_result_realtime = alu_branch_result;
    wire [31:0] pc_abs_addr;
    assign pc_abs_addr =
        (controls[`CON_PC_JUMP] == `PC_JUMP_IMME) ? imme_extented :
        (controls[`CON_PC_JUMP] == `PC_JUMP_REG) ? reg_read1_data :
        32'h0;
    wire [31:0] pc_branch_addr;
    assign pc_branch_addr = imme_extented;
    wire [1:0] _pc_inc;
    assign _pc_inc = 
        (((controls[`CON_PC_INC] == `PC_INC_BRANCH) && (alu_branch_result == 1'b0)) ? `PC_INC_NORMAL :
        controls[`CON_PC_INC]) | _syscall_pc_inc_mask;
    assign pc_inc_realtime =
        (clr == 1'b1) ? 2'b00 :
        _pc_inc;
    // OUTPUT
    wire [31:0] _next_pc;
    //// MODULE
    pc_calculator main_pc_calculator(
        .last_pc(current_pc),
        .pc_inc(_pc_inc),
        .abs_addr(pc_abs_addr),
        .branch_addr(pc_branch_addr),
        .next_pc(_next_pc)
    );
    assign next_pc_realtime =
        (clr == 1'b1) ? 32'h00000000 :
        _next_pc;

    /* TEMP Syscall Handle */
    wire _syscall;
    assign _syscall =
        ((ins[`INS_RAW_OPCODE] == 6'b000000) && (ins[`INS_RAW_FUNCT] == `INS_R_SYSCALL)) ? 1'b1 :
        1'b0;
    reg [1:0] _syscall_pc_inc_mask = 2'b00;
    wire [31:0] _syscall_reg_v0;
    assign _syscall_reg_v0 = reg_read1_data_redirected;
    wire [31:0] _syscall_reg_a0;
    assign _syscall_reg_a0 = reg_read2_data_redirected;
    always_ff @(negedge clk) begin
        if(clr) begin
            _syscall_pc_inc_mask <= 2'b00;
        end
        if(_syscall) begin
            if(_syscall_reg_v0 == 32'd10) begin
                _syscall_pc_inc_mask <= `PC_INC_STOP_OR_MASK;
            end else begin
                _syscall_display <= _syscall_reg_a0;
                $display("SYSCALL: %h @ %0t", _syscall_reg_a0, $time);
            end
        end
    end
    /* !END TEMP Syscall Handle */

    // Stage WB Signal
    wire _reg_write_en;
    assign _reg_write_en = controls[`CON_REG_WRITE_EN];
    wire [4:0] _reg_write_num;
    assign _reg_write_num =
        (controls[`CON_REG_WRITE_EN] == `REG_WRITE_EN_F) ? 5'h00 :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_RT) ? ins[`INS_RAW_RT] :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_RD) ? ins[`INS_RAW_RD] :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_31) ? 5'h1f :
        5'h00;
    assign reg_write_num_realtime = _reg_write_num;

    // data redirect signal
    wire [31:0] _reg_write_data;
    assign _reg_write_data =
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_ALU) ? _alu_result :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_PC) ? current_pc+1 :
        32'h0;
    assign con_reg_write_data_realtime = controls[`CON_REG_WRITE_DATA];
    
    always_ff @(posedge clk) begin
        if(clr) begin
            current_pc_ex <= 32'h00000000;
            controls_ex <= `CON_NOP;
            reg_read2_data_ex <= 32'h00000000;
            ins_ex <= 32'h00000000; // NOP (sll $0, $0, $0)
            alu_result <= 32'h00000000;
            alu_zero <= 1'b0;
            //next_pc <= 32'h00000000;
            //pc_inc <= 2'b00;
            reg_write_en <= `REG_WRITE_EN_F;
            reg_write_num <= 5'h00;
            reg_write_data <= 31'h00000000;
        end else begin
            current_pc_ex <= current_pc;
            controls_ex <= controls;
            reg_read2_data_ex <= reg_read2_data_redirected;
            ins_ex <= ins;
            alu_result <= _alu_result;
            alu_zero <= _alu_zero;
            //next_pc <= _next_pc;
            //pc_inc <= _pc_inc;
            reg_write_en <= _reg_write_en;
            reg_write_num <= _reg_write_num;
            reg_write_data <= _reg_write_data;
        end
    end
endmodule
`endif
