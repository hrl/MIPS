`ifndef _cpu_hazard_unit
`define _cpu_hazard_unit

`timescale 1ns / 1ps

`include "defines.vh"

module cpu_hazard_unit(
    input clk, // from global
    input clr, // from global
    input [4:0] reg_read1_num_realtime_id,
    input [4:0] reg_read2_num_realtime_id,
    input [4:0] reg_write_num_realtime_ex,
    input [4:0] reg_write_num_realtime_mem,
    output [4:0] stalls, // IP, ID, EX, MEM, WB
    input [1:0] pc_inc_realtime_ex,
    output [4:0] flushs, // IP, ID, EX, MEM, WB
    output reg [31:0] data_hazard_count = 32'h00000000,
    output reg [31:0] data_hazard_ex_count = 32'h00000000,
    output reg [31:0] data_hazard_mem_count = 32'h00000000,
    output reg [31:0] control_hazard_count = 32'h00000000,
    output reg [31:0] control_hazard_branch_count = 32'h00000000,
    output reg [31:0] control_hazard_jump_count = 32'h00000000
    );
    reg data_hazard;
    reg control_hazard;
    reg _data_hazard_pos;
    reg _control_hazard_type;

    assign stalls[`HAZARD_STALL_EX] = 1'b0;
    assign stalls[`HAZARD_STALL_MEM] = 1'b0;
    assign stalls[`HAZARD_STALL_WB] = 1'b0;
    assign stalls[`HAZARD_STALL_IF] = data_hazard;
    assign stalls[`HAZARD_STALL_ID] = data_hazard;

    assign flushs[`HAZARD_FLUSH_EX] = 1'b0;
    assign flushs[`HAZARD_FLUSH_MEM] = 1'b0;
    assign flushs[`HAZARD_FLUSH_WB] = 1'b0;
    assign flushs[`HAZARD_FLUSH_IF] = 1'b0;
    assign flushs[`HAZARD_FLUSH_ID] = control_hazard;

    always_ff @(negedge clk) begin
        data_hazard <= 1'b0;
        // data hazard detect
        if(reg_write_num_realtime_ex != 5'h00) begin
            if(reg_read1_num_realtime_id == reg_write_num_realtime_ex
                || reg_read2_num_realtime_id == reg_write_num_realtime_ex) begin
                data_hazard <= 1'b1;
                _data_hazard_pos <= 1'b0;
            end
        end
        if(reg_write_num_realtime_mem != 5'h00) begin
            if(reg_read1_num_realtime_id == reg_write_num_realtime_mem
                || reg_read2_num_realtime_id == reg_write_num_realtime_mem) begin
                data_hazard <= 1'b1;
                _data_hazard_pos <= 1'b1;
            end
        end
    end
    always_ff @(negedge clk) begin
        control_hazard <= 1'b0;
        if(pc_inc_realtime_ex == `PC_INC_BRANCH) begin
            control_hazard <= 1'b1;
            _control_hazard_type <= 1'b0;
        end
        if(pc_inc_realtime_ex == `PC_INC_JUMP) begin
            control_hazard <= 1'b1;
            _control_hazard_type <= 1'b1;
        end
    end
    always_ff @(posedge clk) begin
        if(clr) begin
            data_hazard_count <= 32'h00000000;
            data_hazard_ex_count <= 32'h00000000;
            data_hazard_mem_count <= 32'h00000000;
            control_hazard_count <= 32'h00000000;
            control_hazard_branch_count <= 32'h00000000;
            control_hazard_jump_count <= 32'h00000000;
        end else begin
            if(data_hazard == 1'b1) begin
                data_hazard_count <= data_hazard_count + 1;
                if(_data_hazard_pos == 1'b0) begin
                    data_hazard_ex_count <= data_hazard_ex_count + 1;
                end else begin
                    data_hazard_mem_count <= data_hazard_mem_count + 1;
                end
            end
            if(control_hazard == 1'b1) begin
                control_hazard_count <= control_hazard_count + 1;
                if(_control_hazard_type == 1'b0) begin
                    control_hazard_branch_count <= control_hazard_branch_count + 1;
                end else begin
                    control_hazard_jump_count <= control_hazard_jump_count + 1;
                end
            end
        end
    end
endmodule
`endif
