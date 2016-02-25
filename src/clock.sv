`ifndef _clock
`define _clock

`include "defines.vh"

module clock(
    input clk,
    output reg clk_div = 0
    );

    parameter CLK_DIV_N = 5000000;

    reg [31:0] counter = 0;

    always_ff @(posedge clk) begin
        if(counter < CLK_DIV_N) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
            clk_div <= ~clk_div;
        end
    end
endmodule

`endif
