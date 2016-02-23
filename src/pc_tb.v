`timescale 1ns / 1ps

`include "pc.v"
`include "defines.vh"

module pc_tb;
    reg clk;
    reg [1:0] pc_inc_type;
    reg alu_branch_result;
    reg [31:0] abs_addr;
    reg [31:0] branch_addr;
    wire [31:0] current_pc;

    reg [31:0] current_pc_e;

    integer fd, cont, dummy, error_count;
    reg [100*8-1:0] str;

    pc pc(
        .clk(clk),
        .pc_inc_type(pc_inc_type),
        .alu_branch_result(alu_branch_result),
        .abs_addr(abs_addr),
        .branch_addr(branch_addr),
        .current_pc(current_pc)
    );

    always #5 clk = ~clk;

    initial begin
        fd = $fopen("pc_tb.txt", "r");
        clk = 0;
        error_count = 0;
        cont = 1;
        while(cont) begin
            cont = $fgets(str, fd);
            if((str >> ((cont-1)*8)) != "#" && cont) begin
                @(posedge clk);
                dummy = $sscanf(str, "%x %b %x %x %x", pc_inc_type, alu_branch_result, abs_addr, branch_addr, current_pc_e);
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
