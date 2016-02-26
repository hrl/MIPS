`timescale 1ns / 1ps

`include "cp0.sv"

module cp0_tb;
    reg clk;
    reg clr;
    reg [31:0] current_pc;
    reg [7:0] hardware_interrupt;
    reg eret;
    wire pc_jump;
    wire [31:0] pc_addr;
    wire writeback_mask;
    wire [31:0] status; // direct out
    wire [31:0] epc; // stacked
    wire interrupt;

    reg pc_jump_e;
    reg [31:0] pc_addr_e;
    reg writeback_mask_e;
    reg [31:0] epc_e;
    reg interrupt_e;

    integer fd, cont, dummy, error_count;
    reg [100*8-1:0] str;

    cp0 cp0_test(
        .clk(clk),
        .clr(clr),
        .current_pc(current_pc),
        .hardware_interrupt(hardware_interrupt),
        .eret(eret),
        .pc_jump(pc_jump),
        .pc_addr(pc_addr),
        .writeback_mask(writeback_mask),
        .status(status),
        .epc(epc),
        .interrupt(interrupt)
    );

    always #5 clk = ~clk;

    initial begin
        fd = $fopen("cp0_tb.txt", "r");
        clk = 0;
        clr = 1;
        #10;
        clr = 0;
        error_count = 0;
        cont = 1;
        while(cont) begin
            cont = $fgets(str, fd);
            if((str >> ((cont-1)*8)) != "#" && cont) begin
                @(negedge clk);
                dummy = $sscanf(str, "%x %b %b %b %x %b %b", current_pc, hardware_interrupt, eret, pc_jump_e, pc_addr_e, writeback_mask_e, interrupt_e);
                @(posedge clk);
                #1;
                if(pc_jump_e != pc_jump || pc_addr_e != pc_addr || writeback_mask_e != writeback_mask || interrupt_e != interrupt) begin
                    error_count = error_count + 1;
                    $display("%0t", $time);
                    $display("except: pc_jump:%b pc_addr:%x", pc_jump_e, pc_addr_e);
                    $display("error:  pc_jump:%b pc_addr:%x", pc_jump, pc_addr);
                    $display("");
                end
            end
        end
        $display("Errors: %d", error_count);
        $finish;
    end
endmodule
