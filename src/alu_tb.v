`timescale 1ns / 1ps

`include "alu.v"

module alu_tb;
    reg [3:0] op;
    reg [31:0] a;
    reg [31:0] b;
    wire [31:0] result;
    wire zero;

    reg clk;
    reg [31:0] result_e;
    reg zero_e;
    integer fd, cont, dummy, error_count;
    reg [0:32*8-1] str;
    
    alu alu(.op(op), .a(a), .b(b), .result(result), .zero(zero));

    always #5 clk = ~clk;

    initial begin
        fd = $fopen("alu_tb.txt", "r");
        clk = 0;
        op = `ALU_OP_NOP;
        a = 32'h00000000;
        b = 32'h00000000;
        error_count = 0;
        cont = 1;
        while(cont) begin
            cont = $fgets(str, fd);
            if(str[0] != "#") begin
                dummy = $sscanf(str, "%x %x %x %x %b", op, a, b, result_e, zero_e);
                @(posedge clk);
                if(result_e != result || zero_e != zero) begin
                    error_count = error_count + 1;
                    $display("op:%x a:%x b:%x", op, a, b);
                    $display("except: result:%x zero:%b", result_e, zero_e);
                    $display("error:  result:%x zero:%b", result, zero);
                    $display("");
                end
            end
        end
        $display("Errors: %d", error_count);
        $finish;
    end
endmodule
