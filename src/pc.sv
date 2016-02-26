`ifndef _pc
`define _pc

`include "defines.vh"

/*
* negedge clk: update _pc
*
* all value ignore low bits
*/

module pc(
    input clk,
    input clr, // set pc to 32'h0
    input [31:0] last_pc,
    input [1:0] pc_inc, // 00: pc += 1; 01: pc += 1 + imme; 10: pc = reg/imme, 11: halt
    input alu_branch_result, // 0: normal; 1: branch
    input [31:0] abs_addr,
    input [31:0] branch_addr,
    output reg [31:0] current_pc = 0,
    output reg [31:0] cycle_count = 0
    );

    wire [31:0] normal_pc;
    wire [31:0] branched_pc;

    assign normal_pc = last_pc + 1;
    assign branched_pc = last_pc + 1 + $signed(branch_addr);
    reg halt = 0;

    always_ff @(negedge clk) begin
        if (clr) begin
            current_pc <= 32'h0;
            cycle_count <= 32'h1;
            halt <= 1'b0;
        end else begin
            case (pc_inc)
                `PC_INC_NORMAL: current_pc <= normal_pc;
                `PC_INC_BRANCH: current_pc <= alu_branch_result ? branched_pc : normal_pc;
                `PC_INC_JUMP: current_pc <= abs_addr;
                `PC_INC_STOP: current_pc <= last_pc;
                default: current_pc <= last_pc;
            endcase
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
