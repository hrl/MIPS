`ifndef _cpu_monitor
`define _cpu_monitor

`include "defines.vh"

module cpu_monitor(
    input clk,
    input clr, // set pc to 32'h0
    input [1:0] pc_inc, // 00: pc += 1; 01/10: pc = next_pc, 11: halt
    output reg [31:0] cycle_count = 32'h00000001,
    output reg halt
    );
    reg [1:0] halt_delay_count = 2'b00;

    always_ff @(negedge clk) begin
        if (clr) begin
            cycle_count <= 32'h1;
            halt <= 1'b0;
            halt_delay_count <= 1'b0;
        end else begin
            if(halt == 1'b0) begin
                cycle_count <= cycle_count + 1;
            end
            if(pc_inc == `PC_INC_STOP) begin
                if(halt_delay_count == 2'h2) begin
                    halt <= 1'b1;
                end else begin
                    halt_delay_count <= halt_delay_count + 1;
                end
            end
        end
    end
endmodule
`endif
