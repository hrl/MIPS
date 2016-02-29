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
    output [4:0] stalls // IP, ID, EX, MEM, WB
    );
    reg data_hazard;

    assign stalls[`HAZARD_STALL_EX] = 1'b0;
    assign stalls[`HAZARD_STALL_MEM] = 1'b0;
    assign stalls[`HAZARD_STALL_WB] = 1'b0;
    assign stalls[`HAZARD_STALL_IF] = data_hazard;
    assign stalls[`HAZARD_STALL_ID] = data_hazard;

    always_ff @(negedge clk) begin
        data_hazard <= 1'b0;
        // data hazard detect
        if(reg_write_num_realtime_ex != 5'h00) begin
            if(reg_read1_num_realtime_id == reg_write_num_realtime_ex
                || reg_read2_num_realtime_id == reg_write_num_realtime_ex) begin
                data_hazard <= 1'b1;
            end
        end
        if(reg_write_num_realtime_mem != 5'h00) begin
            if(reg_read1_num_realtime_id == reg_write_num_realtime_mem
                || reg_read2_num_realtime_id == reg_write_num_realtime_mem) begin
                data_hazard <= 1'b1;
            end
        end
    end
endmodule
`endif
