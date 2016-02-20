`ifndef _regfile
`define _regfile

module regfile(
    input [4:0] read1_num,
    input [4:0] read2_num,
    input [4:0] write_num,
    input [31:0] write_data,
    input write_en,
    input clk,
    output [31:0] read1_data,
    output [31:0] read2_data
    );
    reg [31:0] mem [31:0];
    
    initial begin
        mem[0] = 32'h00000000;
    end
    
    always @(negedge clk) begin // posedge: read; negedge: write
        if(write_en && write_num != 5'b00000) begin
            mem[write_num] <= write_data;
        end
    end
    
    assign read1_data = mem[read1_num];
    assign read2_data = mem[read2_num];
endmodule

`endif