`ifndef _cpu_mem
`define _cpu_mem

`timescale 1ns / 1ps

`include "defines.vh"
`include "ram.sv"

module cpu_mem(
    input clk, // from global
    input clr, // from global
    input [31:0] current_pc, // from EX
    input cp0_writeback_mask, // from EX
    input [`CON_MSB:`CON_LSB] controls, // from EX
    input [31:0] reg_read2_data, // from EX
    input [31:0] alu_result, // from EX
    input reg_write_en, // from EX
    input [4:0] reg_write_num, // from EX
    output reg reg_write_en_mem, // latch
    output reg [4:0] reg_write_num_mem, //latch
    output reg [31:0] dm_read_data,
    output reg [31:0] reg_write_data,
    output [4:0] reg_write_num_realtime // actually same as reg_write_num
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
        .cs(controls[`CON_MEM_CS] & cp0_writeback_mask),
        .rd(controls[`CON_MEM_RD]),
        .oe(controls[`CON_MEM_RD]), // same as rd
        .clk(clk),
        .write_data(dm_write_data),
        .read_data(_dm_read_data)
    );

    // Stage WB Signal
    wire [31:0] _reg_write_data;
    assign _reg_write_data =
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_ALU) ? alu_result :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_DM) ? _dm_read_data :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_PC) ? current_pc+1 :
        32'h0;
    assign reg_write_num_realtime = reg_write_num;
    
    always_ff @(posedge clk) begin
        if(clr) begin
            reg_write_en_mem <= `REG_WRITE_EN_F;
            reg_write_num_mem <= 5'h00;
            dm_read_data <= 31'h00000000;
            reg_write_data <= 31'h00000000;
        end else begin
            reg_write_en_mem <= reg_write_en;
            reg_write_num_mem <= reg_write_num;
            dm_read_data <= _dm_read_data;
            reg_write_data <= _reg_write_data;
        end
    end
endmodule
`endif
