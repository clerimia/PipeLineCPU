`timescale 1ns / 1ps

// EX/MEM流水线寄存器
// 功能：在执行和访存阶段之间传递数据和控制信号
module EX_MEM_Register(
    input CLK,                      // 时钟信号
    input RST,                      // 复位信号
    
    // 输入：控制信号
    input RegWre_in,
    input mRD_in,
    input mWR_in,
    input DBDataSrc_in,
    input WrRegDSrc_in,
    
    // 输入：数据
    input [31:0] ALU_result_in,
    input [31:0] ReadData2_in,      // 用于SW指令
    input [4:0] WriteReg_in,
    input zero_in,
    
    // 输出：控制信号
    output reg RegWre_out,
    output reg mRD_out,
    output reg mWR_out,
    output reg DBDataSrc_out,
    output reg WrRegDSrc_out,
    
    // 输出：数据
    output reg [31:0] ALU_result_out,
    output reg [31:0] ReadData2_out,
    output reg [4:0] WriteReg_out,
    output reg zero_out
);

    initial begin
        RegWre_out = 0;
        mRD_out = 0;
        mWR_out = 0;
        DBDataSrc_out = 0;
        WrRegDSrc_out = 0;
        ALU_result_out = 0;
        ReadData2_out = 0;
        WriteReg_out = 0;
        zero_out = 0;
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            // 复位时清除所有信号
            RegWre_out <= 0;
            mRD_out <= 0;
            mWR_out <= 0;
            DBDataSrc_out <= 0;
            WrRegDSrc_out <= 0;
            ALU_result_out <= 0;
            ReadData2_out <= 0;
            WriteReg_out <= 0;
            zero_out <= 0;
        end
        else begin
            // 传递控制信号
            RegWre_out <= RegWre_in;
            mRD_out <= mRD_in;
            mWR_out <= mWR_in;
            DBDataSrc_out <= DBDataSrc_in;
            WrRegDSrc_out <= WrRegDSrc_in;
            
            // 传递数据
            ALU_result_out <= ALU_result_in;
            ReadData2_out <= ReadData2_in;
            WriteReg_out <= WriteReg_in;
            zero_out <= zero_in;
        end
    end

endmodule
