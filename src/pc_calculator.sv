`ifndef _pc_calculator
`define _pc_calculator

`include "defines.vh"

/*
* negedge clk: update _pc
*
* all value ignore low bits
*/

module pc_calculator(
    input [31:0] last_pc,
    input [1:0] pc_inc, // 00: pc += 1; 01: pc += 1 + imme; 10: pc = reg/imme, 11: halt
    input alu_branch_result, // 0: normal; 1: branch
    input [31:0] abs_addr,
    input [31:0] branch_addr,
    output reg [31:0] next_pc = 0
    );

    wire [31:0] normal_pc;
    assign normal_pc = last_pc + 1;
    wire [31:0] branched_pc;
    assign branched_pc = last_pc + 1 + $signed(branch_addr);

    always_comb begin
        case (pc_inc)
            `PC_INC_NORMAL: next_pc <= normal_pc;
            `PC_INC_BRANCH: next_pc <= alu_branch_result ? branched_pc : normal_pc;
            `PC_INC_JUMP: next_pc <= abs_addr;
            `PC_INC_STOP: next_pc <= last_pc;
            default: next_pc <= last_pc;
        endcase
    end
endmodule

`endif
