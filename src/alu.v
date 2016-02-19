`ifndef _alu
`define _alu

`include "defines.vh"

module alu(
    input [3:0] op,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] result,
    output zero
    );
    
    always @(*) begin
        case (op)
            `ALU_OP_ADD: result <= a + b;
            `ALU_OP_SUB: result <= a - b;
            `ALU_OP_SLL: result <= a << b[4:0];
            `ALU_OP_SRA: result <= $signed(a) >>> b[4:0];
            `ALU_OP_SRL: result <= a >> b[4:0];
            `ALU_OP_OR: result <= a | b;
            `ALU_OP_NOR: result <= ~(a | b);
            `ALU_OP_AND: result <= a & b;
            `ALU_OP_NAND: result <= ~(a & b);
            `ALU_OP_XOR: result <= a ^ b;
            `ALU_OP_NXOR: result <= ~(a ^ b);
            `ALU_OP_LST: result <= ($signed(a) < $signed(b)) ? 32'h00000001 : 32'h00000000;
            `ALU_OP_LSTU: result <= ($unsigned(a) < $unsigned(b)) ? 32'h00000001 : 32'h00000000;
            default: result <= 32'hxxxxxxxx;
        endcase
    end
    
    assign zero = (result == 32'h00000000);
    
endmodule

`endif