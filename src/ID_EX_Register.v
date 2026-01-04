`timescale 1ns / 1ps

// ID/EX流水线寄存器
// 功能：在译码和执行阶段之间传递数据和控制信号
module ID_EX_Register(
    input CLK,                      // 时钟信号
    input RST,                      // 复位信号
    input ID_EX_Flush,              // 清空信号（用于分支预测失败时清空流水线）
    
    // 输入：指令控制信号
    input RegWre_in,                // 寄存器写使能信号
    input [1:0] RegDst_in,          // 寄存器写入目标选择信号
    input ALUSrcA_in,               // ALU操作数A源选择信号
    input ALUSrcB_in,               // ALU操作数B源选择信号
    input [2:0] ALUOp_in,           // ALU操作码
    input mRD_in,                   // 内存读使能信号
    input mWR_in,                   // 内存写使能信号
    input DBDataSrc_in,             // 数据总线数据源选择信号
    input WrRegDSrc_in,             // 写入寄存器的数据源选择信号
    
    // 输入：数据
    input [31:0] PC_in,             // 程序计数器值
    input [31:0] ReadData1_in,      // 寄存器文件读取数据1
    input [31:0] ReadData2_in,      // 寄存器文件读取数据2
    input [31:0] extend_in,         // 符号扩展后的立即数
    input [4:0] rs_in,              // 源寄存器rs索引
    input [4:0] rt_in,              // 源寄存器rt索引
    input [4:0] rd_in,              // 目标寄存器rd索引
    input [4:0] sa_in,              // 移位量
    
    // 输出：指令控制信号
    output reg RegWre_out,          // 寄存器写使能信号
    output reg [1:0] RegDst_out,    // 寄存器写入目标选择信号
    output reg ALUSrcA_out,         // ALU操作数A源选择信号
    output reg ALUSrcB_out,         // ALU操作数B源选择信号
    output reg [2:0] ALUOp_out,     // ALU操作码
    output reg mRD_out,             // 内存读使能信号
    output reg mWR_out,             // 内存写使能信号
    output reg DBDataSrc_out,       // 数据总线数据源选择信号
    output reg WrRegDSrc_out,       // 写入寄存器的数据源选择信号
    
    // 输出：数据
    output reg [31:0] PC_out,       // 程序计数器值
    output reg [31:0] ReadData1_out, // 寄存器文件读取数据1
    output reg [31:0] ReadData2_out, // 寄存器文件读取数据2
    output reg [31:0] extend_out,   // 符号扩展后的立即数
    output reg [4:0] rs_out,        // 源寄存器rs索引
    output reg [4:0] rt_out,        // 源寄存器rt索引
    output reg [4:0] rd_out,        // 目标寄存器rd索引
    output reg [4:0] sa_out         // 移位量
);

    initial begin
        RegWre_out = 0;
        RegDst_out = 0;
        ALUSrcA_out = 0;
        ALUSrcB_out = 0;
        ALUOp_out = 0;
        mRD_out = 0;
        mWR_out = 0;
        DBDataSrc_out = 0;
        WrRegDSrc_out = 0;
        PC_out = 0;
        ReadData1_out = 0;
        ReadData2_out = 0;
        extend_out = 0;
        rs_out = 0;
        rt_out = 0;
        rd_out = 0;
        sa_out = 0;
    end

    always @(posedge CLK or negedge RST) begin
        if (!RST || ID_EX_Flush) begin
            // 复位或清空时，清除所有控制信号和数据
            RegWre_out <= 0;
            RegDst_out <= 0;
            ALUSrcA_out <= 0;
            ALUSrcB_out <= 0;
            ALUOp_out <= 0;
            mRD_out <= 0;
            mWR_out <= 0;
            DBDataSrc_out <= 0;
            WrRegDSrc_out <= 0;
            PC_out <= 0;
            ReadData1_out <= 0;
            ReadData2_out <= 0;
            extend_out <= 0;
            rs_out <= 0;
            rt_out <= 0;
            rd_out <= 0;
            sa_out <= 0;
        end
        else begin
            // 传递控制信号
            RegWre_out <= RegWre_in;
            RegDst_out <= RegDst_in;
            ALUSrcA_out <= ALUSrcA_in;
            ALUSrcB_out <= ALUSrcB_in;
            ALUOp_out <= ALUOp_in;
            mRD_out <= mRD_in;
            mWR_out <= mWR_in;
            DBDataSrc_out <= DBDataSrc_in;
            WrRegDSrc_out <= WrRegDSrc_in;
            
            // 传递数据
            PC_out <= PC_in;
            ReadData1_out <= ReadData1_in;
            ReadData2_out <= ReadData2_in;
            extend_out <= extend_in;
            rs_out <= rs_in;
            rt_out <= rt_in;
            rd_out <= rd_in;
            sa_out <= sa_in;
        end
    end

endmodule