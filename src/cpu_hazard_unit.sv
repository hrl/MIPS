`ifndef _cpu_hazard_unit
`define _cpu_hazard_unit

`timescale 1ns / 1ps

`include "defines.vh"

module cpu_hazard_unit(
    input clk, // from global
    input clr, // from global
    // data hazard
    input [4:0] reg_read1_num_realtime_id,
    input [4:0] reg_read2_num_realtime_id,
    input [4:0] reg_write_num_realtime_ex,
    input [4:0] reg_write_num_realtime_mem,
    input [1:0] con_reg_write_data_realtime_ex,
    output [4:0] stalls, // IP, ID, EX, MEM, WB
    output reg [1:0] reg_read1_data_redirect,
    output reg [1:0] reg_read2_data_redirect,
    // control hazard
    input [1:0] pc_inc_realtime_ex,
    output [4:0] flushs, // IP, ID, EX, MEM, WB
    // debug count
    output reg [31:0] data_hazard_count = 32'h00000000,
    output reg [31:0] data_hazard_redirect_count = 32'h00000000,
    output reg [31:0] data_hazard_stall_count = 32'h00000000,
    output reg [31:0] control_hazard_count = 32'h00000000,
    output reg [31:0] control_hazard_branch_count = 32'h00000000,
    output reg [31:0] control_hazard_jump_count = 32'h00000000
    );
    reg data_hazard;
    reg control_hazard;
    reg data_hazard_stall;
    reg control_hazard_type;
    reg [1:0] _reg_read1_data_redirect;
    reg [1:0] _reg_read2_data_redirect;

    assign stalls[`HAZARD_STALL_EX] = 1'b0;
    assign stalls[`HAZARD_STALL_MEM] = 1'b0;
    assign stalls[`HAZARD_STALL_WB] = 1'b0;
    assign stalls[`HAZARD_STALL_IF] = data_hazard_stall;
    assign stalls[`HAZARD_STALL_ID] = data_hazard_stall;

    assign flushs[`HAZARD_FLUSH_EX] = 1'b0;
    assign flushs[`HAZARD_FLUSH_MEM] = 1'b0;
    assign flushs[`HAZARD_FLUSH_WB] = 1'b0;
    assign flushs[`HAZARD_FLUSH_IF] = 1'b0;
    assign flushs[`HAZARD_FLUSH_ID] = control_hazard;

    always_ff @(negedge clk) begin
        data_hazard <= 1'b0;
        data_hazard_stall <= 1'b0;
        _reg_read1_data_redirect <= `HAZARD_REDIRECT_DISABLE;
        _reg_read2_data_redirect <= `HAZARD_REDIRECT_DISABLE;
        // data hazard detect
        if(reg_read1_num_realtime_id == reg_write_num_realtime_ex) begin
            if(reg_write_num_realtime_ex != 5'h00) begin
                if(con_reg_write_data_realtime_ex == `REG_WRITE_DATA_DM) begin
                    data_hazard <= 1'b1;
                    data_hazard_stall <= 1'b1;
                end else begin
                    data_hazard <= 1'b1;
                    data_hazard_stall <= 1'b0;
                    _reg_read1_data_redirect <= `HAZARD_REDIRECT_EX;
                end
            end
        end else if(reg_read1_num_realtime_id == reg_write_num_realtime_mem) begin
            if(reg_write_num_realtime_mem != 5'h00) begin
                data_hazard <= 1'b1;
                data_hazard_stall <= 1'b0;
                _reg_read1_data_redirect <= `HAZARD_REDIRECT_MEM;
            end
        end

        if(reg_read2_num_realtime_id == reg_write_num_realtime_ex) begin
            if(reg_write_num_realtime_ex != 5'h00) begin
                if(con_reg_write_data_realtime_ex == `REG_WRITE_DATA_DM) begin
                    data_hazard <= 1'b1;
                    data_hazard_stall <= 1'b1;
                end else begin
                    data_hazard <= 1'b1;
                    data_hazard_stall <= 1'b0;
                    _reg_read2_data_redirect <= `HAZARD_REDIRECT_EX;
                end
            end
        end else if(reg_read2_num_realtime_id == reg_write_num_realtime_mem) begin
            if(reg_write_num_realtime_mem != 5'h00) begin
                data_hazard <= 1'b1;
                data_hazard_stall <= 1'b0;
                _reg_read2_data_redirect <= `HAZARD_REDIRECT_MEM;
            end
        end
    end
    always_ff @(negedge clk) begin
        control_hazard <= 1'b0;
        if(pc_inc_realtime_ex == `PC_INC_BRANCH) begin
            control_hazard <= 1'b1;
            control_hazard_type <= 1'b0;
        end
        if(pc_inc_realtime_ex == `PC_INC_JUMP) begin
            control_hazard <= 1'b1;
            control_hazard_type <= 1'b1;
        end
    end
    always_ff @(posedge clk) begin
        if(clr) begin
            reg_read1_data_redirect <= `HAZARD_REDIRECT_DISABLE;
            reg_read2_data_redirect <= `HAZARD_REDIRECT_DISABLE;
        end else begin
            reg_read1_data_redirect <= _reg_read1_data_redirect;
            reg_read2_data_redirect <= _reg_read2_data_redirect;
        end
    end
    `ifdef _DEBUG_MODE_CPU
    always_ff @(posedge clk) begin
        if(clr) begin
            data_hazard_count <= 32'h00000000;
            data_hazard_redirect_count <= 32'h00000000;
            data_hazard_stall_count <= 32'h00000000;
            control_hazard_count <= 32'h00000000;
            control_hazard_branch_count <= 32'h00000000;
            control_hazard_jump_count <= 32'h00000000;
        end else begin
            if(data_hazard == 1'b1) begin
                data_hazard_count <= data_hazard_count + 1;
                if(data_hazard_stall == 1'b0) begin
                    data_hazard_redirect_count <= data_hazard_redirect_count + 1;
                end else begin
                    data_hazard_stall_count <= data_hazard_stall_count + 1;
                end
            end
            if(control_hazard == 1'b1) begin
                control_hazard_count <= control_hazard_count + 1;
                if(control_hazard_type == 1'b0) begin
                    control_hazard_branch_count <= control_hazard_branch_count + 1;
                end else begin
                    control_hazard_jump_count <= control_hazard_jump_count + 1;
                end
            end
        end
    end
    `endif
endmodule
`endif
