`ifndef _cpu_mem
`define _cpu_mem

`timescale 1ns / 1ps

`include "defines.vh"
`include "ram.sv"

module cpu_mem(
    input clk, // from global
    input clr, // from global
    input [31:0] current_pc, // from EX
    input [31:0] ins, // from EX
    input [`CON_MSB:`CON_LSB] controls, // from EX
    input [31:0] reg_read2_data, // from EX
    input [31:0] alu_result, // from EX
    output reg [31:0] dm_read_data,
    output reg reg_write_en,
    output reg [4:0] reg_write_num,
    output reg [31:0] reg_write_data
    );
    /* Data Memory */
    //// VAR
    // INPUT
    wire [7:0] dm_addr;
    assign dm_addr = alu_result[9:2]; // ignore low bits
    // in control: controls
    // in global: clk
    wire [31:0] dm_write_data;
    assign dm_write_data = reg_read2_data;
    // OUTPUT
    wire [31:0] _dm_read_data;
    //// module
    ram data_memory(
        .addr(dm_addr),
        .cs(controls[`CON_MEM_CS]),
        .rd(controls[`CON_MEM_RD]),
        .oe(controls[`CON_MEM_RD]), // same as rd
        .clk(clk),
        .write_data(dm_write_data),
        .read_data(_dm_read_data)
    );

    // Stage WB Signal
    wire _reg_write_en;
    assign _reg_write_en = controls[`CON_REG_WRITE_EN];
    wire [4:0] _reg_write_num;
    assign _reg_write_num =
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_RT) ? ins[`INS_RAW_RT] :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_RD) ? ins[`INS_RAW_RD] :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_31) ? 5'h1f :
        5'h0;
    wire [31:0] _reg_write_data;
    assign _reg_write_data =
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_ALU) ? alu_result :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_DM) ? _dm_read_data :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_PC) ? current_pc+1 :
        32'h0;
    
    always_ff @(posedge clk) begin
        if(clr) begin
            dm_read_data <= 31'h00000000;
            reg_write_en <= `REG_WRITE_EN_F;
            reg_write_num <= 5'h00;
            reg_write_data <= 31'h00000000;
        end else begin
            dm_read_data <= _dm_read_data;
            reg_write_en <= _reg_write_en;
            reg_write_num <= _reg_write_num;
            reg_write_data <= _reg_write_data;
        end
    end
endmodule
`endif
