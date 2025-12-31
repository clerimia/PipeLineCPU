`timescale 1ns / 1ps

// IF/ID流水线寄存器
// 功能：在取指和译码阶段之间传递数据
module IF_ID_Register(
    input CLK,                      // 时钟信号
    input RST,                      // 复位信号
    input IF_ID_Write,              // 写使能信号（用于流水线暂停）
    input IF_Flush,                 // 清空信号（用于分支预测错误）
    input [31:0] PC_in,             // 输入：当前PC值
    input [31:0] instruction_in,    // 输入：指令
    output reg [31:0] PC_out,       // 输出：PC值
    output reg [31:0] instruction_out // 输出：指令
);

    initial begin
        PC_out = 0;
        instruction_out = 0;
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            // 复位时清空寄存器
            PC_out <= 0;
            instruction_out <= 0;
        end
        else if (IF_Flush) begin
            // 清空流水线，输入无效
            PC_out <= 0;
            instruction_out <= 32'h00000000; // NOP指令
        end
        else if (IF_ID_Write) begin
            // 写入数据
            PC_out <= PC_in;
            instruction_out <= instruction_in;
        end
        // 如果IF_ID_Write无效，则保持当前值，即流水线暂停
    end

endmodule
