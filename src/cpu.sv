`ifndef _cpu
`define _cpu

`timescale 1ns / 1ps

`include "defines.vh"
`include "alu.sv"
`include "regfile.sv"
`include "rom.sv"
`include "ram.sv"
`include "pc.sv"
`include "control.sv"

module cpu(
    `ifndef _DEBUG_MODE_CPU
    input clk,
    input pc_clr,
    input cpu_clr,
    output [31:0] display,
    output [31:0] cycles,
    output halt
    `endif
    );
    reg [31:0] display_reg;
    reg halt_reg = 0;
    `ifndef _DEBUG_MODE_CPU
    assign display = display_reg;
    assign cycles = cycle_count;
    assign halt = halt_reg;
    `endif

    /* Debug Sim */
    `ifdef _DEBUG_MODE_CPU
        reg clk;
        reg pc_clr;
        reg cpu_clr;
        always #5 clk = ~clk;
        initial begin
            clk = 0;
            pc_clr = 1;
            cpu_clr = 1;
            #10;
            pc_clr = 0;
            cpu_clr = 0;
        end
    `endif
    `ifdef _DEBUG_MODE_RAM
        wire dm_cs;
        wire dm_rd;
        assign dm_cs = controls[`CON_MEM_CS];
        assign dm_rd = controls[`CON_MEM_RD];
    `endif
    
    /* TEMP Syscall Handle */
    wire _syscall;
    assign _syscall =
        ((ins[`INS_RAW_OPCODE] == 6'b000000) && (ins[`INS_RAW_FUNCT] == `INS_R_SYSCALL)) ? 1'b1 :
        1'b0;
    wire [31:0] _syscall_reg_v0;
    wire [31:0] _syscall_reg_a0;
    reg [1:0] _syscall_pc_inc_mask;
    always_ff @(posedge clk) begin
        if(cpu_clr) begin
            _syscall_pc_inc_mask <= 2'b00;
        end
        if(_syscall) begin
            if(_syscall_reg_v0 == 32'd10) begin
                halt_reg <= 1'b1;
                _syscall_pc_inc_mask <= `PC_INC_STOP_OR_MASK;
            end else begin
                display_reg <= _syscall_reg_a0;
                $display("SYSCALL: %h @ %0t", _syscall_reg_a0, $time);
            end
        end else begin
                halt_reg <= 1'b0;
        end
    end
    /* !END TEMP Syscall Handle */
    
    /* Global */
    wire [31:0] imme_extented;
    assign imme_extented = 
        (controls[`CON_IMME_EXT] == `IMME_EXT_ZERO) ? {16'h0, ins[`INS_RAW_IMME]} :
        (controls[`CON_IMME_EXT] == `IMME_EXT_SIGN) ? {(ins[`INS_RAW_IMME_SIGN] == 1'b0) ? 16'h0000: 16'hffff, ins[`INS_RAW_IMME]} :
        32'h0;
    wire [31:0] shamt_extented;
    assign shamt_extented = {27'h0, ins[`INS_RAW_SHAMT]};

    /* Program Counter */
    //// VAR
    // INPUT
    // in global: clk
    // in global: pc_clr
    // in control: controls
    wire alu_branch_result;
    assign alu_branch_result =
        (controls[`CON_ALU_BRANCH] == `ALU_BRANCH_BEQ) ? alu_zero :
        (controls[`CON_ALU_BRANCH] == `ALU_BRANCH_BNE) ? !alu_zero :
        1'h0;
    wire [31:0] pc_abs_addr;
    assign pc_abs_addr =
        (controls[`CON_PC_JUMP] == `PC_JUMP_IMME) ? imme_extented :
        (controls[`CON_PC_JUMP] == `PC_JUMP_REG) ? reg_read1_data :
        32'h0;
    wire [31:0] pc_branch_addr;
    assign pc_branch_addr = imme_extented;
    // OUTPUT
    wire [31:0] current_pc;
    wire [31:0] cycle_count;
    //// MODULE
    pc main_pc(
        .clk(clk),
        .clr(pc_clr),
        .last_pc(current_pc),
        .pc_inc(controls[`CON_PC_INC] | _syscall_pc_inc_mask),
        .alu_branch_result(alu_branch_result),
        .abs_addr(pc_abs_addr),
        .branch_addr(pc_branch_addr),
        .current_pc(current_pc),
        .cycle_count(cycle_count)
    );

    /* Ins Memory */
    //// VAR
    // INPUT
    wire [7:0] ins_addr;
    assign ins_addr = current_pc[7:0];
    // OUTPUT
    wire [31:0] ins;
    //// MODULE
    rom ins_memory(
        .addr(ins_addr),
        .cs(1),
        .read_data(ins)
    );

    /* Control */
    //// VAR
    // INPUT
    // in im: ins
    // OUTPUT
    wire [`CON_MSB:`CON_LSB] controls;
    //// MODULE
    control main_control(
        .ins(ins),
        .controls(controls)
    );

    /* Register File */
    //// VAR
    // INPUT
    wire [4:0] reg_read1_num;
    assign reg_read1_num =
        (controls[`CON_REG_READ1_NUM] == `REG_READ1_NUM_RS) ? ins[`INS_RAW_RS] :
        (controls[`CON_REG_READ1_NUM] == `REG_READ1_NUM_RT) ? ins[`INS_RAW_RT] :
        5'h0;
    wire [4:0] reg_read2_num;
    assign reg_read2_num =
        (controls[`CON_REG_READ2_NUM] == `REG_READ2_NUM_RS) ? ins[`INS_RAW_RS] :
        (controls[`CON_REG_READ2_NUM] == `REG_READ2_NUM_RT) ? ins[`INS_RAW_RT] :
        5'h0;
    wire [4:0] reg_write_num;
    assign reg_write_num =
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_RT) ? ins[`INS_RAW_RT] :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_RD) ? ins[`INS_RAW_RD] :
        (controls[`CON_REG_WRITE_NUM] == `REG_WRITE_NUM_31) ? 5'h1f :
        5'h0;
    wire [31:0] reg_write_data;
    assign reg_write_data =
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_ALU) ? alu_result :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_DM) ? dm_read_data :
        (controls[`CON_REG_WRITE_DATA] == `REG_WRITE_DATA_PC) ? current_pc+1 :
        32'h0;
    // in control: controls
    // in global: clk
    // OUTPUT
    wire [31:0] reg_read1_data;
    wire [31:0] reg_read2_data;
    //// MODULE
    regfile main_regfile(
        .read1_num(reg_read1_num),
        .read2_num(reg_read2_num),
        .write_num(reg_write_num),
        .write_data(reg_write_data),
        .write_en(controls[`CON_REG_WRITE_EN]),
        .clk(clk),
        .read1_data(reg_read1_data),
        .read2_data(reg_read2_data),
        ._direct_out_v0(_syscall_reg_v0),
        ._direct_out_a0(_syscall_reg_a0)
    );

    /* Arithmetic Logic Unit */
    //// VAR
    // INPUT
    // in control: controls
    wire [31:0] alu_a;
    assign alu_a =
        (controls[`CON_ALU_A] == `ALU_A_REG) ? reg_read1_data:
        (controls[`CON_ALU_A] == `ALU_A_IMME) ? imme_extented:
        32'h0;
    wire [31:0] alu_b;
    assign alu_b =
        (controls[`CON_ALU_B] == `ALU_B_REG) ? reg_read2_data:
        (controls[`CON_ALU_B] == `ALU_B_IMME) ? imme_extented:
        (controls[`CON_ALU_B] == `ALU_B_SHAMT) ? shamt_extented:
        32'h0;
    // OUTPUT
    wire [31:0] alu_result;
    wire alu_zero;
    //// MODULE
    alu main_alu(
        .op(controls[`CON_ALU_OP]),
        .a(alu_a),
        .b(alu_b),
        .result(alu_result),
        .zero(alu_zero)
    );

    /* Data Memory */
    //// VAR
    // INPUT
    wire [7:0] dm_addr;
    assign dm_addr = alu_result[9:2]; // ignore low bits
    // in control: controls
    // in global: clk
    wire [31:0] dm_write_data;
    assign dm_write_data = reg_read2_data;
    // OUTPUT
    wire [31:0] dm_read_data;
    //// module
    ram data_memory(
        .addr(dm_addr),
        .cs(controls[`CON_MEM_CS]),
        .rd(controls[`CON_MEM_RD]),
        .oe(controls[`CON_MEM_RD]), // same as rd
        .clk(clk),
        .write_data(dm_write_data),
        .read_data(dm_read_data)
    );
    
endmodule

`endif
