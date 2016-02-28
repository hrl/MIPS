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
    output reg [31:0] cycle_count
    );
    /* Program Counter Flip-Flop */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // OUTPUT
    wire [31:0] _current_pc;
    wire [31:0] _cycle_count;
    //// MODULE
    pc_ff main_pc_ff(
        .clk(clk),
        .clr(clr),
        .next_pc(next_pc),
        .pc_inc(pc_inc),
        .current_pc(_current_pc),
        .cycle_count(_cycle_count)
    );

    /* Ins Memory */
    //// VAR
    // INPUT
    wire [15:0] ins_addr;
    assign ins_addr = current_pc[15:0];
    // OUTPUT
    wire [31:0] _ins;
    //// MODULE
    rom ins_memory(
        .addr(ins_addr),
        .cs(1),
        .read_data(_ins)
    );

    always_ff @(posedge clk) begin
        if(clr) begin
            current_pc <= 32'h00000000;
            ins <= 32'h00000000; // NOP (sll $0, $0, $0)
            cycle_count <= 32'h00000000;
        end else begin
            current_pc <= _current_pc;
            ins <= _ins;
            cycle_count <= _cycle_count;
        end
    end
endmodule
`endif
