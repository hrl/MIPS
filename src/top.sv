`ifndef _top
`define _top

`include "defines.vh"
`include "cpu.sv"
`include "clock.sv"
`include "seg_display.sv"

module top(
    input clk,
    input [2:0] hardware_interrupt,
    output [7:0] display_data,
    output [7:0] display_en
    );
`ifndef _DEBUG_MODE_CPU
    /* Global */
    wire cpu_clk;
    wire seg_clk;
    clock #(2000000) clock_cpu_50hz(
        .clk(clk),
        .clk_div(cpu_clk)
    );

    clock #(100000) clock_seg_display_1000hz(
        .clk(clk),
        .clk_div(seg_clk)
    );

    seg_display seg_display_cpu(
        .clk(seg_clk),
        .datas(cpu_display),
        .display_data(display_data),
        .display_en(display_en)
    );

    /* CPU */
    //// VAR
    // INPUT
    // in global: cpu_clk;
    reg cpu_pc_clr = 1;
    reg cpu_cpu_clr = 1;
    always_ff @(negedge cpu_clk) begin
        cpu_pc_clr <= 0;
        cpu_cpu_clr <= 0;
    end
    // OUTPUT
    wire [31:0] cpu_display;
    wire [31:0] cpu_cycles;
    wire halt;
    //// MODULE
    cpu main_cpu(
        .clk(cpu_clk),
        .pc_clr(cpu_pc_clr),
        .cpu_clr(cpu_cpu_clr),
        .hardware_interrupt({5'b0, hardware_interrupt}),
        .display(cpu_display),
        .cycles(cpu_cycles),
        .halt(halt)
    );
`endif
endmodule

`endif
