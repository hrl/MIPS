`ifndef _cpu
`define _cpu

`timescale 1ns / 1ps

`include "defines.vh"
`include "cpu_hazard_unit.sv"
`include "cpu_if.sv"
`include "cpu_id_wb.sv"
`include "cpu_ex.sv"
`include "cpu_mem.sv"

/*
* 5 stage pipeline CPU
* posedge clk: latch value (between stages)
* negedge clk: write back (reg/mem), set stall/flush
*/

module cpu(
    `ifndef _DEBUG_MODE_CPU
    input clk,
    input clk_delay,
    input clr,
    input [7:0] hardware_interrupt,
    `endif
    output [31:0] cycle_count,
    output [31:0] display,
    output halt
    );
    /* Wire Defines */
    // Hazard Unit
    wire [4:0] reg_read1_num_realtime_id;
    wire [4:0] reg_read2_num_realtime_id;
    wire [4:0] reg_write_num_realtime_ex;
    wire [4:0] reg_write_num_realtime_mem;
    wire [1:0] con_reg_write_data_realtime_ex;
    wire [4:0] stalls;
    wire [1:0] reg_read1_data_redirect;
    wire [1:0] reg_read2_data_redirect;
    wire [4:0] flushs;
    wire [31:0] data_hazard_count;
    wire [31:0] data_hazard_redirect_count;
    wire [31:0] data_hazard_stall_count;
    wire [31:0] control_hazard_count;
    wire [31:0] control_hazard_branch_count;
    wire [31:0] control_hazard_jump_count;
    // Stage IF->ID 
    wire [31:0] current_pc_if;
    wire [31:0] ins_if;
    wire [31:0] cycle_count_if;
    // Stage ID->EX
    wire [31:0] current_pc_id;
    wire [31:0] ins_id;
    wire [`CON_MSB:`CON_LSB] controls_id;
    wire eret_id;
    wire [31:0] reg_read1_data_id;
    wire [31:0] reg_read2_data_id;
    // Stage EX->MEM
    wire [31:0] current_pc_ex;
    wire [31:0] ins_ex;
    wire [`CON_MSB:`CON_LSB] controls_ex;
    wire [31:0] reg_read2_data_ex;
    wire [31:0] alu_result_ex;
    wire  alu_zero_ex;
    wire cp0_writeback_mask_ex;
    wire [31:0] next_pc_realtime_ex;
    wire [1:0] pc_inc_realtime_ex;
    wire reg_write_en_ex;
    wire [31:0] reg_write_data_ex;
    wire [4:0] reg_write_num_ex;
    wire [31:0] _syscall_display_ex;
    // Stage MEM->WB
    wire reg_write_en_mem;
    wire [4:0] reg_write_num_mem;
    wire [31:0] dm_read_data_mem;
    wire [31:0] reg_write_data_mem;
    /* !END Wire Defines */

    /* Global */
    assign cycle_count = cycle_count_if;
    assign display = _syscall_display_ex;
    assign halt = halt_if;

    /* Debug Sim */
    `ifdef _DEBUG_MODE_CPU
        reg [1:0] counter;
        reg clk = 0;
        reg clk_delay = 0;
        reg clr;
        reg [7:0] hardware_interrupt;
        always #1 counter = counter + 1;
        always_ff @(posedge counter[0] iff counter[1] == 1'b0) begin
            clk = ~clk;
        end
        always_ff @(posedge counter[1]) begin
            clk_delay = ~clk_delay;
        end
        initial begin
            counter = 2'h0;
            clr = 1;
            hardware_interrupt = 8'h00;
            #10;
            clr = 0;
            #1000;
            hardware_interrupt[0] = 1'b1;
            #100;
            hardware_interrupt[0] = 1'b0;
        end
        always_ff @(posedge clk iff halt) begin
            $display("HALT, cycle_count: %d", cycle_count-1);
            $display("HALT, data_hazard_count: %d", data_hazard_count);
            $display("HALT, data_hazard_redirect_count: %d", data_hazard_redirect_count);
            $display("HALT, data_hazard_stall_count: %d", data_hazard_stall_count);
            $display("HALT, control_hazard_count: %d", control_hazard_count);
            $display("HALT, control_hazard_branch_count: %d", control_hazard_branch_count);
            $display("HALT, control_hazard_jump_count: %d", control_hazard_jump_count);
            $finish;
        end
    `endif
    
    /* Hazard Unit */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // in id: reg_read1_num_realtime_id
    // in id: reg_read2_num_realtime_id
    // in ex: reg_write_num_realtime_ex
    // in mem: reg_write_num_realtime_mem
    // in ex: con_reg_write_data_realtime_ex
    // in ex: pc_inc_realtime_ex
    // OUTPUT
    // wire [4:0] stalls
    // wire [1:0] reg_read1_data_redirect
    // wire [1:0] reg_read2_data_redirect
    // wire [4:0] flushs
    //// MODULE
    cpu_hazard_unit hazard_unit(
        .clk(clk),
        .clr(clr),
        // data hazard
        .reg_read1_num_realtime_id(reg_read1_num_realtime_id),
        .reg_read2_num_realtime_id(reg_read2_num_realtime_id),
        .reg_write_num_realtime_ex(reg_write_num_realtime_ex),
        .reg_write_num_realtime_mem(reg_write_num_realtime_mem),
        .con_reg_write_data_realtime_ex(con_reg_write_data_realtime_ex),
        .stalls(stalls),
        .reg_read1_data_redirect(reg_read1_data_redirect),
        .reg_read2_data_redirect(reg_read2_data_redirect),
        // control hazard
        .pc_inc_realtime_ex(pc_inc_realtime_ex),
        .flushs(flushs),
        // debug count
        .data_hazard_count(data_hazard_count),
        .data_hazard_redirect_count(data_hazard_redirect_count),
        .data_hazard_stall_count(data_hazard_stall_count),
        .control_hazard_count(control_hazard_count),
        .control_hazard_branch_count(control_hazard_branch_count),
        .control_hazard_jump_count(control_hazard_jump_count)
    );

    /* Stage IF */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // in ex: pc_inc_realtime_ex
    // in ex: next_pc_realtime_ex
    // OUTPUT
    // wire [31:0] current_pc_if;
    // wire [31:0] ins_if;
    // wire [31:0] cycle_count_if;
    // wire halt_if;
    wire [31:0] _debug_current_pc_if;
    wire [31:0] _debug_ins_if;
    wire [31:0] _debug_cycle_count_if;
    //// MODULE
    cpu_if stage_if(
        .clk(clk),
        .clr(clr),
        .pc_inc(pc_inc_realtime_ex),
        .next_pc(next_pc_realtime_ex),
        .stall(stalls[`HAZARD_STALL_IF]),
        .current_pc(current_pc_if),
        .ins(ins_if),
        .cycle_count(cycle_count_if),
        .halt(halt_if),
        ._debug_current_pc(_debug_current_pc_if),
        ._debug_ins(_debug_ins_if),
        ._debug_cycle_count(_debug_cycle_count_if)
    );

    /* Stage ID & WB */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // in if: current_pc_if
    // in if: ins_if
    // in mem: reg_write_en_mem
    // in mem: reg_write_num_mem
    // in mem: reg_write_data_mem
    // OUTPUT
    // wire [31:0] current_pc_id;
    // wire [31:0] ins_id;
    // wire [`CON_MSB:`CON_LSB] controls_id;
    // wire eret_id;
    // wire [31:0] reg_read1_data_id;
    // wire [31:0] reg_read2_data_id;
    // wire [4:0] reg_read1_num_realtime_id
    // wire [4:0] reg_read2_num_realtime_id
    //// MODULE
    cpu_id_wb stage_id_wb(
        .clk(clk),
        .clr(clr | flushs[`HAZARD_FLUSH_ID]),
        .current_pc(current_pc_if),
        .ins(ins_if),
        .reg_write_en(reg_write_en_mem),
        .reg_write_num(reg_write_num_mem),
        .reg_write_data(reg_write_data_mem),
        .stall(stalls[`HAZARD_STALL_ID]),
        .current_pc_id(current_pc_id),
        .ins_id(ins_id),
        .controls(controls_id),
        .eret(eret_id),
        .reg_read1_data(reg_read1_data_id),
        .reg_read2_data(reg_read2_data_id),
        .reg_read1_num_realtime(reg_read1_num_realtime_id),
        .reg_read2_num_realtime(reg_read2_num_realtime_id)
    );

    /* Stage EX */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // in id: current_pc_id
    // in id: ins_id
    // in id: controls_id
    // in id: reg_read1_data_id
    // in id: reg_read2_data_id
    // in hazard: reg_read1_data_redirect
    // in hazard: reg_read2_data_redirect
    // in hazard: reg_write_data_mem
    // OUTPUT
    // wire [31:0] current_pc_ex;
    // wire [31:0] ins_ex;
    // wire [`CON_MSB:`CON_LSB] controls_ex;
    // wire [31:0] reg_read2_data_ex;
    // wire [31:0] alu_result_ex;
    // wire  alu_zero_ex;
    // wire [31:0] next_pc_realtime_ex;
    // wire [1:0] pc_inc_realtime_ex;
    // wire reg_write_en_ex;
    // wire [4:0] reg_write_num_ex;
    // wire [4:0] reg_write_num_realtime_ex;
    // wire [1:0] con_reg_write_data_realtime_ex;
    // wire [31:0] reg_write_data;
    // wire [31:0] _syscall_display_ex;
    wire _debug_syscall;
    wire [1:0] _debug_syscall_pc_inc_mask;
    wire _debug_cp0_pc_jump;
    wire [31:0] _debug_cp0_pc_addr;
    wire _debug_cp0_interrupt;
    wire [31:0] _debug_cp0_status;
    //// MODULE
    cpu_ex stage_ex(
        .clk(clk),
        .clk_delay(clk_delay),
        .clr(clr),
        .hardware_interrupt(hardware_interrupt),
        .current_pc(current_pc_id),
        .ins(ins_id),
        .controls(controls_id),
        .eret(eret_id),
        .reg_read1_data(reg_read1_data_id),
        .reg_read2_data(reg_read2_data_id),
        // latch signal
        .current_pc_ex(current_pc_ex),
        .ins_ex(ins_ex),
        .controls_ex(controls_ex),
        .reg_read2_data_ex(reg_read2_data_ex),
        // stage EX output
        .alu_result(alu_result_ex),
        .alu_zero(alu_zero_ex),
        .cp0_writeback_mask(cp0_writeback_mask_ex),
        // pc change signal
        .next_pc_realtime(next_pc_realtime_ex),
        .pc_inc_realtime(pc_inc_realtime_ex),
        // hazard detect signal
        .reg_write_en(reg_write_en_ex),
        .reg_write_num(reg_write_num_ex),
        .reg_write_num_realtime(reg_write_num_realtime_ex),
        // data redirect signal
        .reg_read1_data_redirect(reg_read1_data_redirect),
        .reg_read2_data_redirect(reg_read2_data_redirect),
        .reg_write_data_mem(reg_write_data_mem),
        .con_reg_write_data_realtime(con_reg_write_data_realtime_ex),
        .reg_write_data(reg_write_data_ex),
        // syscall signal
        ._syscall_display(_syscall_display_ex),
        // debug signal
        ._debug_syscall(_debug_syscall),
        ._debug_syscall_pc_inc_mask(_debug_syscall_pc_inc_mask),
        ._debug_cp0_pc_jump(_debug_cp0_pc_jump),
        ._debug_cp0_pc_addr(_debug_cp0_pc_addr),
        ._debug_cp0_status(_debug_cp0_status),
        ._debug_cp0_interrupt(_debug_cp0_interrupt)
    );

    /* Stage MEM */
    //// VAR
    // INPUT
    // in global: clk
    // in global: clr
    // in ex: current_pc_ex
    // in ex: ins_ex
    // in ex: controls_ex
    // in ex: reg_read2_data_ex
    // in ex: alu_result_ex
    // in ex: reg_write_en_ex
    // in ex: reg_write_num_ex
    // OUTPUT
    // wire reg_write_en_mem;
    // wire [4:0] reg_write_num_mem;
    // wire [31:0] dm_read_data_mem;
    // wire [31:0] reg_write_data_mem;
    // wire [4:0] reg_write_num_realtime;
    //// MODULE
    cpu_mem stage_mem(
        .clk(clk),
        .clr(clr),
        .cp0_writeback_mask(cp0_writeback_mask_ex),
        .current_pc(current_pc_ex),
        .controls(controls_ex),
        .reg_read2_data(reg_read2_data_ex),
        .alu_result(alu_result_ex),
        .reg_write_en(reg_write_en_ex),
        .reg_write_num(reg_write_num_ex),
        .dm_read_data(dm_read_data_mem),
        .reg_write_en_mem(reg_write_en_mem),
        .reg_write_num_mem(reg_write_num_mem),
        .reg_write_data(reg_write_data_mem),
        .reg_write_num_realtime(reg_write_num_realtime_mem)
    );
endmodule

`endif
