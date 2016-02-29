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
* negedge clk: write back (reg/mem)
*/

module cpu(
    `ifndef _DEBUG_MODE_CPU
    input clk,
    input clr,
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
    wire [4:0] stalls;
    wire [4:0] flushs;
    wire [31:0] data_hazard_count;
    wire [31:0] data_hazard_ex_count;
    wire [31:0] data_hazard_mem_count;
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
    wire [31:0] reg_read1_data_id;
    wire [31:0] reg_read2_data_id;
    wire [31:0] _syscall_reg_v0_id;
    wire [31:0] _syscall_reg_a0_id;
    // Stage EX->MEM
    wire [31:0] current_pc_ex;
    wire [31:0] ins_ex;
    wire [`CON_MSB:`CON_LSB] controls_ex;
    wire [31:0] reg_read2_data_ex;
    wire [31:0] alu_result_ex;
    wire  alu_zero_ex;
    wire [31:0] next_pc_realtime_ex;
    wire [1:0] pc_inc_realtime_ex;
    wire reg_write_en_ex;
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
        reg clk;
        reg clr;
        always #5 clk = ~clk;
        initial begin
            clk = 0;
            clr = 1;
            #10;
            clr = 0;
        end
        always_ff @(posedge clk iff halt) begin
            $display("HALT, cycle_count: %d", cycle_count-1);
            $display("HALT, data_hazard_count: %d", data_hazard_count);
            $display("HALT, data_hazard_mem_count: %d", data_hazard_mem_count-data_hazard_ex_count);
            $display("HALT, data_hazard_ex_mem_count: %d", data_hazard_mem_count>>1);
            $display("HALT, control_hazard_count: %d", control_hazard_count);
            $display("HALT, control_hazard_branch_count: %d", control_hazard_branch_count);
            $display("HALT, control_hazard_jump_count: %d", control_hazard_jump_count);
            $finish;
        end
    `endif
    
    /* Hazard Unit */
    cpu_hazard_unit data_hazard_unit(
        .clk(clk),
        .clr(clr),
        .reg_read1_num_realtime_id(reg_read1_num_realtime_id),
        .reg_read2_num_realtime_id(reg_read2_num_realtime_id),
        .reg_write_num_realtime_ex(reg_write_num_realtime_ex),
        .reg_write_num_realtime_mem(reg_write_num_realtime_mem),
        .stalls(stalls),
        .pc_inc_realtime_ex(pc_inc_realtime_ex),
        .flushs(flushs),
        .data_hazard_count(data_hazard_count),
        .data_hazard_ex_count(data_hazard_ex_count),
        .data_hazard_mem_count(data_hazard_mem_count),
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
    // wire [31:0] reg_read1_data_id;
    // wire [31:0] reg_read2_data_id;
    // wire [31:0] _syscall_reg_v0_id;
    // wire [31:0] _syscall_reg_a0_id;
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
        .reg_read1_data(reg_read1_data_id),
        .reg_read2_data(reg_read2_data_id),
        .reg_read1_num_realtime(reg_read1_num_realtime_id),
        .reg_read2_num_realtime(reg_read2_num_realtime_id),
        ._direct_out_v0(_syscall_reg_v0_id),
        ._direct_out_a0(_syscall_reg_a0_id)
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
    // wire [31:0] _syscall_display_ex;
    wire _debug_syscall;
    wire [1:0] _debug_syscall_pc_inc_mask;
    //// MODULE
    cpu_ex stage_ex(
        .clk(clk),
        .clr(clr),
        .current_pc(current_pc_id),
        .ins(ins_id),
        .controls(controls_id),
        .reg_read1_data(reg_read1_data_id),
        .reg_read2_data(reg_read2_data_id),
        .current_pc_ex(current_pc_ex),
        .ins_ex(ins_ex),
        .controls_ex(controls_ex),
        .reg_read2_data_ex(reg_read2_data_ex),
        .alu_result(alu_result_ex),
        .alu_zero(alu_zero_ex),
        .next_pc_realtime(next_pc_realtime_ex),
        .pc_inc_realtime(pc_inc_realtime_ex),
        .reg_write_en(reg_write_en_ex),
        .reg_write_num(reg_write_num_ex),
        .reg_write_num_realtime(reg_write_num_realtime_ex),
        ._syscall_reg_v0(_syscall_reg_v0_id),
        ._syscall_reg_a0(_syscall_reg_a0_id),
        ._syscall_display(_syscall_display_ex),
        ._debug_syscall(_debug_syscall),
        ._debug_syscall_pc_inc_mask(_debug_syscall_pc_inc_mask)
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
    //// MODULE
    cpu_mem stage_mem(
        .clk(clk),
        .clr(clr),
        .current_pc(current_pc_ex),
        .ins(ins_ex),
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
