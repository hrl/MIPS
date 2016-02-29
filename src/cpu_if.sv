`ifndef _cpu_if
`define _cpu_if

`timescale 1ns / 1ps

`include "defines.vh"
`include "rom.sv"
`include "cpu_monitor.sv"

module cpu_if(
    input clk, // from global
    input clr, // from global
    input [1:0] pc_inc, // from EX
    input [31:0] next_pc, // from EX
    input stall, // 0: normal; 1: keep pc
    output reg [31:0] current_pc,
    output reg [31:0] ins,
    output reg [31:0] cycle_count,
    output reg halt,
    output [31:0] _debug_current_pc,
    output [31:0] _debug_ins,
    output [31:0] _debug_cycle_count
    );
    assign _debug_current_pc = _current_pc;
    assign _debug_ins = _ins;
    assign _debug_cycle_count = _cycle_count;

    /* Monitor */
    wire [31:0] _cycle_count;
    wire _halt;
    cpu_monitor monitor(
        .clk(clk),
        .clr(clr),
        .pc_inc(pc_inc),
        .cycle_count(_cycle_count),
        .halt(_halt)
    );

    // PC Choose (add/jump/stall)
    wire [31:0] _current_pc;
    assign _current_pc =
        (clr == 1'b1) ? 32'h00000000 :
        (stall == 1'b1) ? current_pc :
        (pc_inc == `PC_INC_NORMAL) ? current_pc + 1 :
        next_pc;

    /* Ins Memory */
    //// VAR
    // INPUT
    wire [15:0] ins_addr;
    assign ins_addr = _current_pc[15:0];
    // OUTPUT
    wire [31:0] _ins;
    //// MODULE
    rom ins_memory(
        .addr(ins_addr),
        .cs(1'b1),
        .read_data(_ins)
    );

    always_ff @(posedge clk) begin
        if(clr) begin
            current_pc <= 32'h00000000;
            ins <= _ins;
            cycle_count <= 32'h00000001;
            halt <= 0;
        end else begin
            if(stall == 1'b1) begin
                halt <= 0;
            end else begin
                halt <= _halt;
            end
            current_pc <= _current_pc;
            ins <= _ins;
            cycle_count <= _cycle_count;
        end
    end
endmodule
`endif
