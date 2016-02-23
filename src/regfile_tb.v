`timescale 1ns / 1ps

`include "regfile.v"

module regfile_tb;
    reg [4:0] read1_num;
    reg [4:0] read2_num;
    reg [4:0] write_num;
    reg [31:0] write_data;
    reg write_en;
    reg clk;
    wire [31:0] read1_data;
    wire [31:0] read2_data;

    reg [31:0] read1_data_e;
    reg [31:0] read2_data_e;
    integer fd, cont, dummy, error_count;
    reg [100*8-1:0] str;
    
    regfile regfile(
        .read1_num(read1_num),
        .read2_num(read2_num),
        .write_num(write_num),
        .write_data(write_data),
        .write_en(write_en),
        .clk(clk),
        .read1_data(read1_data),
        .read2_data(read2_data)
    );

    always #5 clk = ~clk;

    initial begin
        fd = $fopen("regfile_tb.txt", "r");
        clk = 0;
        write_en = 0;
        error_count = 0;
        cont = 1;
        while(cont) begin
            cont = $fgets(str, fd);
            if((str >> ((cont-1)*8)) != "#" && cont) begin
                @(posedge clk);
                dummy = $sscanf(str, "%d %d %d %x %b %x %x", read1_num, read2_num, write_num, write_data, write_en, read1_data_e, read2_data_e);
                #1;
                if(read1_data_e != read1_data || read2_data_e != read2_data) begin
                    error_count = error_count + 1;
                    $display("except: read1:%x read2:%x", read1_data_e, read2_data_e);
                    $display("error:  read1:%x read2:%x", read1_data, read2_data);
                    $display("");
                end
            end
        end
        $display("Errors: %d", error_count);
        $finish;
    end
endmodule
