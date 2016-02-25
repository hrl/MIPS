`ifndef _seg_display
`define _seg_display

module seg_display(
    input clk,
    input [31:0] datas,
    output [7:0] display_data,
    output [7:0] display_en
    );
    
    reg [2:0] index = 0;

    wire [31:0] datas_shifted;
    assign datas_shifted = datas >> {index, 2'b00};
    wire [3:0] data;
    assign data = datas_shifted[3:0];

    always_ff @(posedge clk) begin
        index = index + 1;
    end

    function [7:0] hex_to_7seg;
        input [3:0] data_hex;
        begin
            case (data_hex)
                4'h0: hex_to_7seg = 8'b00000011;
                4'h1: hex_to_7seg = 8'b10011111;
                4'h2: hex_to_7seg = 8'b00100101;
                4'h3: hex_to_7seg = 8'b00001101;
                4'h4: hex_to_7seg = 8'b10011001;
                4'h5: hex_to_7seg = 8'b01001001;
                4'h6: hex_to_7seg = 8'b01000001;
                4'h7: hex_to_7seg = 8'b00011011;
                4'h8: hex_to_7seg = 8'b00000001;
                4'h9: hex_to_7seg = 8'b00001001;
                4'ha: hex_to_7seg = 8'b00010001;
                4'hb: hex_to_7seg = 8'b11000001;
                4'hc: hex_to_7seg = 8'b01100011;
                4'hd: hex_to_7seg = 8'b10000101;
                4'he: hex_to_7seg = 8'b01100001;
                4'hf: hex_to_7seg = 8'b01110001;
                default: hex_to_7seg = 8'b11111111;
            endcase
        end
    endfunction
    
    function [7:0] index_to_en;
        input [2:0] index;
        begin
            case (index)
                3'h0: index_to_en = 8'b11111110;
                3'h1: index_to_en = 8'b11111101;
                3'h2: index_to_en = 8'b11111011;
                3'h3: index_to_en = 8'b11110111;
                3'h4: index_to_en = 8'b11101111;
                3'h5: index_to_en = 8'b11011111;
                3'h6: index_to_en = 8'b10111111;
                3'h7: index_to_en = 8'b01111111;
            endcase
        end
    endfunction

    assign display_data = hex_to_7seg(data);
    assign display_en = index_to_en(index);
endmodule
`endif
