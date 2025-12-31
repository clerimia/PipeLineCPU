`timescale 1ns / 1ps

// MEM/WB流水线寄存器
// 功能：在访存和写回阶段之间传递数据和控制信号
module MEM_WB_Register(
    input CLK,                      // 时钟信号
    input RST,                      // 复位信号
    
    // 输入：控制信号
    input RegWre_in,
    input DBDataSrc_in,
    input WrRegDSrc_in,
    
    // 输入：数据
    input [31:0] MemData_in,        // 从存储器读取的数据
    input [31:0] ALU_result_in,     // ALU结果
    input [4:0] WriteReg_in,
    
    // 输出：控制信号
    output reg RegWre_out,
    output reg DBDataSrc_out,
    output reg WrRegDSrc_out,
    
    // 输出：数据
    output reg [31:0] MemData_out,
    output reg [31:0] ALU_result_out,
    output reg [4:0] WriteReg_out
);

    initial begin
        RegWre_out = 0;
        DBDataSrc_out = 0;
        WrRegDSrc_out = 0;
        MemData_out = 0;
        ALU_result_out = 0;
        WriteReg_out = 0;
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            // 复位时清除所有信号
            RegWre_out <= 0;
            DBDataSrc_out <= 0;
            WrRegDSrc_out <= 0;
            MemData_out <= 0;
            ALU_result_out <= 0;
            WriteReg_out <= 0;
        end
        else begin
            // 传递控制信号
            RegWre_out <= RegWre_in;
            DBDataSrc_out <= DBDataSrc_in;
            WrRegDSrc_out <= WrRegDSrc_in;
            
            // 传递数据
            MemData_out <= MemData_in;
            ALU_result_out <= ALU_result_in;
            WriteReg_out <= WriteReg_in;
        end
    end

endmodule
