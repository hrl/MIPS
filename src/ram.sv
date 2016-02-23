`ifndef _ram
`define _ram

module ram(
    input [7:0] addr, // 256 * 4B
    input cs, // chip select
    input rd, // read(1) / write(0)
    input oe, // output enable
    input clk,
    input [31:0] write_data, // 4B
    output [31:0] read_data // 4B
    );

    wire write_in_en;
    wire read_out_en;
    reg [31:0] mem [255:0];

    assign write_in_en = cs & (~rd);
    assign read_out_en = cs & rd & oe;
    assign read_data = read_out_en ? mem[addr] : 32'bz;

    always_ff @(negedge clk) begin
        if(write_in_en) begin
            mem[addr] <= write_data;
        end
    end
endmodule
`endif
