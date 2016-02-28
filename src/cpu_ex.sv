`ifndef _cpu_ex
`define _cpu_ex

`timescale 1ns / 1ps

`include "defines.vh"
`include "alu.sv"

module cpu_ex(
    input clk, // from global
    input clr, // from global
    input [31:0] current_pc, // from ID
    input [31:0] ins, // from ID
    input [`CON_MSB:`CON_LSB] controls, // from ID
    input [31:0] reg_read1_data, // from ID
    input [31:0] reg_read2_data, // from ID
    output reg [31:0] current_pc_ex, // latch
    output reg [31:0] ins_ex, // latch
    output reg [`CON_MSB:`CON_LSB] controls_ex, // latch
    output reg [31:0] reg_read2_data_ex, // latch
    output reg [31:0] alu_result,
    output reg alu_zero,
    output reg [31:0] next_pc
    );

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
    wire [31:0] alu_a;
    assign alu_a =
        (controls[`CON_ALU_A] == `ALU_A_REG) ? reg_read1_data:
        (controls[`CON_ALU_A] == `ALU_A_IMME) ? imme_extented:
        32'h0;
    wire [31:0] alu_b;
    assign alu_b =
        (controls[`CON_ALU_B] == `ALU_B_REG) ? reg_read2_data:
        (controls[`CON_ALU_B] == `ALU_B_IMME) ? imme_extented:
        (controls[`CON_ALU_B] == `ALU_B_SHAMT) ? shamt_extented:
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
    wire [31:0] pc_abs_addr;
    assign pc_abs_addr =
        (controls[`CON_PC_JUMP] == `PC_JUMP_IMME) ? imme_extented :
        (controls[`CON_PC_JUMP] == `PC_JUMP_REG) ? reg_read1_data :
        32'h0;
    wire [31:0] pc_branch_addr;
    assign pc_branch_addr = imme_extented;
    // OUTPUT
    wire [31:0] _next_pc;
    //// MODULE
    pc_calculator main_pc_calculator(
        .last_pc(current_pc),
        .pc_inc(controls[`CON_PC_INC]),
        .alu_branch_result(alu_branch_result),
        .abs_addr(pc_abs_addr),
        .branch_addr(pc_branch_addr),
        .next_pc(_next_pc)
    );

    always_ff @(posedge clk) begin
        if(clr) begin
            current_pc_ex <= 32'h00000000;
            controls_ex <= `CON_NOP;
            reg_read2_data_ex <= 32'h00000000;
            ins_ex <= 32'h00000000; // NOP (sll $0, $0, $0)
            alu_result <= 32'h00000000;
            alu_zero <= 1'b0;
            next_pc <= 32'h00000000;
        end else begin
            current_pc_ex <= current_pc;
            controls_ex <= controls;
            reg_read2_data_ex <= reg_read2_data;
            ins_ex <= ins;
            alu_result <= _alu_result;
            alu_zero <= _alu_zero;
            next_pc <= _next_pc;
        end
    end
endmodule
`endif
