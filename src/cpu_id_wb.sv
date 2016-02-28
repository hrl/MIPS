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
    output reg [31:0] current_pc_id, // latch
    output reg [31:0] ins_id, // latch
    output reg [`CON_MSB:`CON_LSB] controls,
    output reg [31:0] reg_read1_data,
    output reg [31:0] reg_read2_data,
    output [31:0] _direct_out_v0,
    output [31:0] _direct_out_a0
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
        (_controls[`CON_REG_READ1_NUM] == `REG_READ1_NUM_RS) ? ins[`INS_RAW_RS] :
        (_controls[`CON_REG_READ1_NUM] == `REG_READ1_NUM_RT) ? ins[`INS_RAW_RT] :
        5'h0;
    wire [4:0] reg_read2_num;
    assign reg_read2_num =
        (_controls[`CON_REG_READ2_NUM] == `REG_READ2_NUM_RS) ? ins[`INS_RAW_RS] :
        (_controls[`CON_REG_READ2_NUM] == `REG_READ2_NUM_RT) ? ins[`INS_RAW_RT] :
        5'h0;
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
        .read2_data(_reg_read2_data),
        ._direct_out_v0(_direct_out_v0),
        ._direct_out_a0(_direct_out_a0)
    );

    always_ff @(posedge clk) begin
        if(clr) begin
            controls <= `CON_NOP;
            reg_read1_data <= 32'h00000000;
            reg_read2_data <= 32'h00000000;
            current_pc_id <= 32'h00000000;
            ins_id <= 32'h00000000; // NOP (sll $0, $0, $0)
        end else begin
            controls <= _controls;
            reg_read1_data <= _reg_read1_data;
            reg_read2_data <= _reg_read2_data;
            current_pc_id <= current_pc;
            ins_id <= ins;
        end
    end
endmodule
`endif
