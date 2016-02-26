`ifndef _rom
`define _rom

/*
* Map:
* 0x00xx text
* 0x80xx exception
*/

module rom(
    input [15:0] addr, // (256+256) * 4B
    input cs, // chip select
    output [31:0] read_data // 4B
    );

    reg [31:0] text [255:0];
    reg [31:0] exce [255:0];

    assign read_out_en = cs;
    assign read_data = !read_out_en ? 32'bz :
        (addr[15] == 1'b0) ? text[addr[7:0]] :
        (addr[15] == 1'b1) ? exce[addr[7:0]] :
        32'bz;

    initial begin
        $readmemh(`PROGRAM_FILE, text, 0, 255);
        $readmemh(`EXCEPTION_FILE, exce, 0, 255);
    end

endmodule
`endif
