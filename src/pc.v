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
    input [1:0] pc_inc_type, // 00: pc += 1; 01: pc += 1 + imme; 10: pc = reg/imme
    input alu_branch_result, // 0: normal; 1: branch
    input [31:0] abs_addr,
    input [31:0] branch_addr,
    output [31:0] current_pc
    );

    reg [31:0] _pc;

    wire [31:0] normal_pc;
    wire [31:0] branched_pc;

    assign normal_pc = _pc + 1;
    assign branched_pc = _pc + 1 + $signed(branch_addr);

    assign current_pc = _pc;

    initial begin
        _pc = 32'h00000000;
    end

    always @(negedge clk) begin
        case (pc_inc_type)
            `PC_ADDR_NORMAL: _pc <= normal_pc;
            `PC_ADDR_BRANCH: _pc <= alu_branch_result ? branched_pc : normal_pc;
            `PC_ADDR_JUMP: _pc <= alu_branch_result ? abs_addr : normal_pc;
            `PC_ADDR_UNUSED: _pc <= normal_pc;
        endcase
    end

endmodule

`endif
