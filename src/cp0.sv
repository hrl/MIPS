`ifndef _cp0
`define _cp0

`include "defines.vh"

/*
* TEMP CP0 & Interrupt Handle
*
* Only interrupt, no other exception handle
*
* Interrupt Enable Flag: reg_status[`CP0_REG_STATUS_IE]
*                        1'b0:disable interrupt
*                        1'b1:enable interrupt
*
* Enter: (@posedge clk iff {interrupt, eret} == 2'b10)
* edge            0 a 1 b 2 c 3 d 4 e 5 f 6 g 7
* clk          ___/---\___/---\___/---\___/---\
* clk_delay    -\___/---\___/---\___/---\___/--
* hardware_i   _/------------------------------
* interrupt    ___/-------\____________________
* mask_i       -----\__________________________
* masked_i     _/---\__________________________
* mask_wb      -----\_______/------------------
* pc jump      _____/-------\__________________
* pc           ===x=======x=======x=======x====
* reg/mem wb   _______|_______|_______|_______|
* masked  wb   _______________|_______|_______|
* /0: interrupt <- 1
*     temp <- interrupt_number
*     temp_mask <- to_mask(interrupt_number)
* /a: mask interrupt
*     push temp_mask to mask stack
*     push current_pc to epc stack
*     block write back
*     set pc jump flag
*     // 1)  highest-level interrupt at edge 0 will be masked,
*     //     pc will jump to interrupt_program[temp] at egde a,
*     // 2a) if no other higher-lever interrupt happens between edge 0 and a,
*     //     interrupt flag will be set to false at edge 2.
*     // 2b) if higher-lever interrupt happens between edge 0 and a,
*     //     highest-level interrupt at edge 2 will be handled as in 1),
*     //     at this situation, interrupt flag will keep true between edge 2 and 4,
*     //                        current_pc will be pushed at edge c,
*     //                        pc will jump to another address at edge 4.
*     // 3)  treat ERET as J when pushing next_pc
* situation 2a:
* /2: pc <- interrupt_program[temp]
* /c: clean pc jump flag
*     allow write back
*
* Leave: (@posedge clk iff {interrupt, eret} == 2'b01)
* edge         0 a 1 b 2 c 3 d 4 e 5 f 6 g 7
* clk       ___/---\___/---\___/---\___/---\
* clk_delay -\___/---\___/---\___/---\___/--
* eret      ___/-------\____________________
* pc        ===x=======x=======x=======x====
* /a: pop mask stack then unmask interrupt
*     temp <- pop epc stack
*     set pc jump flag
*     // if other same-or-lower-level interrupt exists,
*     // interrupt check will happen at egde 2,
*     // current_pc will be pushed at edge c,
*     // pc will jump to another address at edge 4.
* /2: pc <- temp
* /c: clean pc jump flag
*
* Leave & Enter: (@posedge clk iff {interrupt, eret} == 2'b11)
* same as Enter
*
*/

module cp0(
    input clk,
    input clk_delay,
    input clr,
    input [31:0] current_pc,
    input [7:0] hardware_interrupt,
    input eret,
    output reg pc_jump = 1'b0,
    output reg [31:0] pc_addr = 32'h0,
    output reg writeback_mask = 1'b1,
    output [31:0] status, // direct out
    output reg [31:0] epc, // stacked
    output reg interrupt = 1'b0
    );
    reg [31:0] reg_status = 32'hffffffff;
    assign status = reg_status;

    // stack frames
    reg [31:0] reg_epc [7:0]; // stacked epc
    reg [7:0] reg_mask [7:0]; // stacked mask

    wire [7:0] _masked_interrupts;
    assign _masked_interrupts = hardware_interrupt & reg_status[`CP0_REG_STATUS_IM];

    reg _interrupt; // wire
    reg [2:0] _interrupt_num; // wire
    reg [7:0] _interrupt_mask; // wire
    always_comb begin
        casez (_masked_interrupts)
            8'b1???????: _interrupt_num = 3'h7;
            8'b01??????: _interrupt_num = 3'h6;
            8'b001?????: _interrupt_num = 3'h5;
            8'b0001????: _interrupt_num = 3'h4;
            8'b00001???: _interrupt_num = 3'h3;
            8'b000001??: _interrupt_num = 3'h2;
            8'b0000001?: _interrupt_num = 3'h1;
            8'b00000001: _interrupt_num = 3'h0;
            default: _interrupt_num = 3'h0;
        endcase
        casez (_masked_interrupts)
            8'b1???????: _interrupt_mask = 8'b01111111;
            8'b01??????: _interrupt_mask = 8'b10111111;
            8'b001?????: _interrupt_mask = 8'b11011111;
            8'b0001????: _interrupt_mask = 8'b11101111;
            8'b00001???: _interrupt_mask = 8'b11110111;
            8'b000001??: _interrupt_mask = 8'b11111011;
            8'b0000001?: _interrupt_mask = 8'b11111101;
            8'b00000001: _interrupt_mask = 8'b11111110;
            default: _interrupt_mask = 8'b11111111;
        endcase
    end
    always_comb begin
        if(reg_status[`CP0_REG_STATUS_IE]) begin
            casez(reg_status[`CP0_REG_STATUS_IM])
                8'b0???????: _interrupt = 1'b0;
                8'b10??????: _interrupt = |(hardware_interrupt[7:7]);
                8'b110?????: _interrupt = |(hardware_interrupt[7:6]);
                8'b1110????: _interrupt = |(hardware_interrupt[7:5]);
                8'b11110???: _interrupt = |(hardware_interrupt[7:4]);
                8'b111110??: _interrupt = |(hardware_interrupt[7:3]);
                8'b1111110?: _interrupt = |(hardware_interrupt[7:2]);
                8'b11111110: _interrupt = |(hardware_interrupt[7:1]);
                default: _interrupt = |(hardware_interrupt[7:0]);
            endcase
        end else begin
            _interrupt = 1'b0;
        end
    end

    reg [2:0] _epc_stack_count = 3'h0; // get updated at posedge clk, shared with mask_stack
    reg [2:0] _epc_stack_count_new = 3'h0;
    reg [7:0] interrupt_mask = 8'b11111111;
    reg [7:0] interrupt_num = 3'h0;

    always_ff @(posedge clk) begin
        if(clr) begin
            interrupt <= 1'b0;
            interrupt_num <= 3'h0;
            interrupt_mask <= 8'b11111111;
            _epc_stack_count <= 3'h0;
        end else begin
            interrupt <= _interrupt;
            interrupt_num <= _interrupt_num;
            interrupt_mask <= _interrupt_mask;
            _epc_stack_count <= _epc_stack_count_new;
        end
    end

    wire [7:0] reg_mask_top;
    wire [31:0] reg_epc_top;
    assign reg_mask_top = reg_mask[_epc_stack_count-1];
    assign reg_epc_top = reg_epc[_epc_stack_count-1];

    always_ff @(posedge clk_delay) begin
        if(clr) begin
            _epc_stack_count_new <= 3'h0;
            reg_status <= {16'h0, 8'hff, 7'h0, 1'h1};
            pc_jump <= 1'b0;
            writeback_mask <= 1'b1;
        end else begin
            case ({interrupt, eret})
                2'b10, 2'b11: begin
                    // enter interrupt
                    // mask int
                    reg_status[`CP0_REG_STATUS_IM] <= reg_status[`CP0_REG_STATUS_IM] & interrupt_mask;
                    // push current_pc; push mask
                    reg_epc[_epc_stack_count] <= current_pc;
                    reg_mask[_epc_stack_count] <= interrupt_mask;
                    _epc_stack_count_new <= _epc_stack_count + 1;
                    // set pc jump flag
                    pc_jump <= 1'b1;
                    pc_addr <= `CP0_INT_BASE + interrupt_num;
                    // block write back
                    writeback_mask <= 1'b0;
                end
                2'b01: begin
                    // leave interrupt
                    // pop pc, pop mask then unmask
                    epc <= reg_epc_top;
                    reg_status[`CP0_REG_STATUS_IM] <= reg_status[`CP0_REG_STATUS_IM] | (~reg_mask_top);
                    _epc_stack_count_new <= _epc_stack_count - 1;
                    // set pc jump flag
                    pc_jump <= 1'b1;
                    pc_addr <= reg_epc_top;
                    // allow write back
                    writeback_mask <= 1'b1;
                end
                default: begin
                    // clean pc jump flag
                    pc_jump <= 1'b0;
                    // allow write back
                    writeback_mask <= 1'b1;
                end
            endcase
        end
    end
endmodule

`endif
