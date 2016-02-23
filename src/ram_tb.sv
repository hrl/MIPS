`timescale 1ns / 1ps

`include "ram.sv"

module ram_tb;
    reg [9:0] addr;
    reg cs; // chip select
    reg rd; // read(1) / write(0)
    reg oe; // output enable
    reg clk;
    reg [31:0] write_data;
    wire [31:0] read_data;

    reg [31:0] read_data_e;
    wire read_out_en;
    assign read_out_en = cs & rd & oe;

    integer fd, cont, dummy, error_count;
    reg [100*8-1:0] str;

    ram ram(
        .addr(addr),
        .cs(cs),
        .rd(rd),
        .oe(oe),
        .clk(clk),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        fd = $fopen("ram_tb.txt", "r");
        clk = 0;
        cs = 0;
        rd = 0;
        oe = 0;
        error_count = 0;
        cont = 1;
        while(cont) begin
            cont = $fgets(str, fd);
            if((str >> ((cont-1)*8)) != "#" && cont) begin
                dummy = $sscanf(str, "%d %b %b %b %x %x", addr, cs, rd, oe, write_data, read_data_e);
                @(negedge clk);
                #1;
                if(read_data_e != read_data) begin
                    error_count = error_count + 1;
                    $display("except: read_data:%x", read_data_e);
                    $display("error:  read_data:%x", read_data);
                    $display("");
                end
            end
        end
        $display("Errors: %d", error_count);
        $finish;
    end
endmodule
