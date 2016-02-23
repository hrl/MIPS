`timescale 1ns / 1ps

`include "pc.sv"
`include "defines.vh"

module pc_tb;
    reg clk;
    reg clr;
    reg [1:0] pc_inc;
    reg alu_branch_result;
    reg [31:0] abs_addr;
    reg [31:0] branch_addr;
    wire [31:0] current_pc;
    wire [31:0] last_pc;

    assign last_pc = current_pc;

    reg [31:0] current_pc_e;

    integer fd, cont, dummy, error_count;
    reg [100*8-1:0] str;

    pc pc(
        .clk(clk),
        .clr(clr),
        .last_pc(last_pc),
        .pc_inc(pc_inc),
        .alu_branch_result(alu_branch_result),
        .abs_addr(abs_addr),
        .branch_addr(branch_addr),
        .current_pc(current_pc)
    );

    always #5 clk = ~clk;

    initial begin
        fd = $fopen("pc_tb.txt", "r");
        clk = 0;
        clr = 1;
        error_count = 0;
        cont = 1;
        while(cont) begin
            cont = $fgets(str, fd);
            if((str >> ((cont-1)*8)) != "#" && cont) begin
                @(posedge clk);
                dummy = $sscanf(str, "%b %x %b %x %x %x", clr, pc_inc, alu_branch_result, abs_addr, branch_addr, current_pc_e);
                #1;
                if(current_pc_e != current_pc) begin
                    error_count = error_count + 1;
                    $display("except: current_pc:%x", current_pc_e);
                    $display("error:  current_pc:%x", current_pc);
                    $display("");
                end
            end
        end
        $display("Errors: %d", error_count);
        $finish;
    end
endmodule
