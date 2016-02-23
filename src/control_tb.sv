`timescale 1ns / 1ps

`include "control.sv"
`include "defines.vh"

module control_tb;
    reg [31:0] ins;
    wire [`CON_MSB:`CON_LSB] controls;

    reg [`CON_MSB:`CON_LSB] controls_e;

    //reg clk;
    //integer fd, cont, dummy, error_count;
    //reg [100*8-1:0] str;

    control control(
        .ins(ins),
        .controls(controls)
    );

    //always #5 clk = ~clk;

    initial begin
        ins = 32'b00000000000000000000000000100000;
        /*
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
        */
    end
endmodule
