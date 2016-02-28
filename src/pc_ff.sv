`ifndef _pc_ff
`define _pc_ff

`include "defines.vh"

module pc_ff(
    input clk,
    input clr, // set pc to 32'h0
    input [31:0] next_pc,
    input [1:0] pc_inc, // 00: pc += 1; 01/10: pc = next_pc, 11: halt
    output reg [31:0] current_pc = 0,
    output reg [31:0] cycle_count = 0
    );
    reg halt = 0;

    always_ff @(negedge clk) begin
        if (clr) begin
            current_pc <= 32'h0;
            cycle_count <= 32'h1;
            halt <= 1'b0;
        end else begin
            if(pc_inc == `PC_INC_NORMAL) begin
                current_pc <= current_pc+1;
            end else begin
                current_pc <= next_pc;
            end
            if(pc_inc != `PC_INC_STOP && halt == 1'b0) begin
                cycle_count <= cycle_count + 1;
            end else begin
                halt <= 1'b1;
            end
        end
        `ifdef _DEBUG_MODE_CPU
            if(pc_inc == `PC_INC_STOP) begin
                $display("HALT, cycle_count: %d", cycle_count);
                $finish;
            end
        `endif
    end
endmodule
`endif
