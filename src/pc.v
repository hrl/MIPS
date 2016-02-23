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
    input [1:0] pc_inc_type, // 00: pc += 1; 01: pc += 1 + imme; 10: pc = reg/imme
    input alu_branch_result, // 0: normal; 1: branch
    input [31:0] abs_addr,
    input [31:0] branch_addr,
    output reg [31:0] current_pc
    );


    wire [31:0] normal_pc;
    wire [31:0] branched_pc;

    assign normal_pc = last_pc + 1;
    assign branched_pc = last_pc + 1 + $signed(branch_addr);
    
    initial begin
        current_pc <= 32'h0;
    end

    always @(negedge clk) begin
        if (clr) begin
            current_pc <= 32'h0;
        end else begin
            case (pc_inc_type)
                `PC_ADDR_NORMAL: current_pc <= normal_pc;
                `PC_ADDR_BRANCH: current_pc <= alu_branch_result ? branched_pc : normal_pc;
                `PC_ADDR_JUMP: current_pc <= abs_addr;
                `PC_ADDR_UNUSED: current_pc <= normal_pc;
            endcase
        end
    end

endmodule

`endif
