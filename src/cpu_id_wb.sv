`ifndef _cpu_id_wb
`define _cpu_id_wb

`timescale 1ns / 1ps

`include "defines.vh"
`include "regfile.sv"
`include "control.sv"

module cpu_id_wb(
    input clk, // from global
    input clr, // from global
    input [31:0] current_pc, // from IF
    input [31:0] ins, // from IF
    input reg_write_en, // from MEM
    input [4:0] reg_write_num, // from MEM
    input [31:0] reg_write_data, // from MEM
    input stall, // 0: normal; 1: clean controls/ins
    output reg [31:0] current_pc_id, // latch
    output reg [31:0] ins_id, // latch
    output reg [`CON_MSB:`CON_LSB] controls,
    output reg [31:0] reg_read1_data,
    output reg [31:0] reg_read2_data,
    output [4:0] reg_read1_num_realtime,
    output [4:0] reg_read2_num_realtime
    );
    /* Control */
    //// VAR
    // INPUT
    // in im: ins
    // OUTPUT
    wire [`CON_MSB:`CON_LSB] _controls;
    //// MODULE
    control main_control(
        .ins(ins),
        .controls(_controls)
    );

    /* Register File */
    //// VAR
    // INPUT
    wire [4:0] reg_read1_num;
    assign reg_read1_num =
        ((ins[`INS_RAW_OPCODE] == 6'b000000) && (ins[`INS_RAW_FUNCT] == `INS_R_SYSCALL)) ? 5'h02 : // 2: v0
        (_controls[`CON_REG_READ1_EN] == `REG_READ1_EN_F) ? 5'h0 :
        (_controls[`CON_REG_READ1_NUM] == `REG_READ1_NUM_RS) ? ins[`INS_RAW_RS] :
        (_controls[`CON_REG_READ1_NUM] == `REG_READ1_NUM_RT) ? ins[`INS_RAW_RT] :
        5'h0;
    assign reg_read1_num_realtime = reg_read1_num;
    wire [4:0] reg_read2_num;
    assign reg_read2_num =
        ((ins[`INS_RAW_OPCODE] == 6'b000000) && (ins[`INS_RAW_FUNCT] == `INS_R_SYSCALL)) ? 5'h04 : // 4: a0
        (_controls[`CON_REG_READ2_EN] == `REG_READ2_EN_F) ? 5'h0 :
        (_controls[`CON_REG_READ2_NUM] == `REG_READ2_NUM_RS) ? ins[`INS_RAW_RS] :
        (_controls[`CON_REG_READ2_NUM] == `REG_READ2_NUM_RT) ? ins[`INS_RAW_RT] :
        5'h0;
    assign reg_read2_num_realtime = reg_read2_num;
    // in global: clk
    // OUTPUT
    wire [31:0] _reg_read1_data;
    wire [31:0] _reg_read2_data;
    //// MODULE
    regfile main_regfile(
        .read1_num(reg_read1_num),
        .read2_num(reg_read2_num),
        .write_num(reg_write_num),
        .write_data(reg_write_data),
        .write_en(reg_write_en),
        .clk(clk),
        .read1_data(_reg_read1_data),
        .read2_data(_reg_read2_data)
    );

    always_ff @(posedge clk) begin
        if(clr) begin
            controls <= `CON_NOP;
            reg_read1_data <= 32'h00000000;
            reg_read2_data <= 32'h00000000;
            current_pc_id <= 32'h00000000;
            ins_id <= 32'h00000000; // NOP (sll $0, $0, $0)
        end else begin
            if(stall == 1'b1) begin
                controls <= `CON_NOP;
                reg_read1_data <= 32'h00000000;
                reg_read2_data <= 32'h00000000;
                ins_id <= 32'h00000000; // NOP (sll $0, $0, $0)
            end else begin
                controls <= _controls;
                reg_read1_data <= _reg_read1_data;
                reg_read2_data <= _reg_read2_data;
                ins_id <= ins;
            end
            current_pc_id <= current_pc;
        end
    end
endmodule
`endif
