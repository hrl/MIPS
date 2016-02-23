`ifndef _rom
`define _rom

module rom(
    input [7:0] addr, // 256 * 4B
    input cs, // chip select
    output [31:0] read_data // 4B
    );

    reg [31:0] mem [255:0];

    assign read_out_en = cs;
    assign read_data = read_out_en ? mem[addr] : 32'bz;

    initial begin
        $readmemh(`PROGRAM_FILE, mem, 0, 255);
    end

endmodule
`endif
