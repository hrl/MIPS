`ifndef _cpu_if
`define _cpu_if

`timescale 1ns / 1ps

`include "defines.vh"
`include "rom.sv"
`include "pc_ff.sv"

module cpu_if(
    input clk, // from global
    input clr, // from global
    input [1:0] pc_inc, // from EX
    input [31:0] next_pc, // from EX
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

    /* Program Counter Flip-Flop */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // OUTPUT
    wire [31:0] _current_pc;
    wire [31:0] _cycle_count;
    wire _halt;
    //// MODULE
    pc_ff main_pc_ff(
        .clk(clk),
        .clr(clr),
        .next_pc(next_pc),
        .pc_inc(pc_inc),
        .current_pc(_current_pc),
        .cycle_count(_cycle_count),
        .halt(_halt)
    );

    /* Ins Memory */
    //// VAR
    // INPUT
    wire [15:0] ins_addr;
    assign ins_addr = 
        (clr == 1'b1) ? 16'h0000 :
        _current_pc[15:0];
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
            ins <= _ins; // handled in ins_addr
            cycle_count <= 32'h00000001;
            halt <= 0;
        end else begin
            current_pc <= _current_pc;
            ins <= _ins;
            cycle_count <= _cycle_count;
            halt <= _halt;
        end
    end
endmodule
`endif
