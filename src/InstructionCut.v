`timescale 1ns / 1ps
// 指令分解模块
// 功能：将32位MIPS指令分解为各个字段，供CPU控制单元使用
// MIPS指令字段说明：
// op[5:0]      : 操作码(Opcode)
// rs[4:0]      : 源寄存器1地址
// rt[4:0]      : 源寄存器2地址/目的寄存器地址(立即数指令)
// rd[4:0]      : 目的寄存器地址(R型指令)
// sa[4:0]      : 移位量(Shift Amount)
// immediate[15:0]: 立即数(I型指令)
// addr[25:0]   : 跳转地址(J型指令)

module InstructionCut(
        input [31:0] instruction,   // 32位MIPS指令输入
        output reg[5:0] op,         // 操作码输出(6位)
        output reg[4:0] rs,         // 源寄存器1地址(5位)
        output reg[4:0] rt,         // 源寄存器2地址(5位)
        output reg[4:0] rd,         // 目的寄存器地址(R型指令)(5位)
        output reg[4:0] sa,         // 移位量(5位)
        output reg[15:0] immediate, // 立即数/偏移量(I型指令)(16位)
        output reg[25:0] addr       // 跳转地址(J型指令)(26位)
    );
    
    // 初始值设定
    initial begin
        op = 6'b000000;
        rs = 5'b00000;
        rt = 5'b00000;
        rd = 5'b00000;
    end
    
    // 指令分解逻辑，当指令输入变化时执行
    always@(instruction)
    begin
        // 从32位指令中提取各个字段
        op = instruction[31:26];     // 操作码(位31-26)
        rs = instruction[25:21];     // 源寄存器1(位25-21)
        rt = instruction[20:16];     // 源寄存器2(位20-16)
        rd = instruction[15:11];     // 目的寄存器(位15-11)
        sa = instruction[10:6];      // 移位量(位10-6)
        immediate = instruction[15:0];// 立即数(位15-0)
        addr = instruction[25:0];    // 跳转地址(位25-0)
    end
endmodule
