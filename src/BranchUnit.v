`timescale 1ns / 1ps

// 分支判断单元
// 功能：在ID阶段处理分支和跳转指令的判断，生成PCSrc控制信号
// 集成数据前推功能以避免分支指令的数据冒险
module BranchUnit(
    // 输入：指令信息
    input [5:0] op,                     // 指令操作码
    input [4:0] rs,                     // 源寄存器rs索引
    input [4:0] rt,                     // 源寄存器rt索引
    
    // 输入：寄存器数据
    input [31:0] ReadData1,             // 寄存器文件读取数据1
    input [31:0] ReadData2,             // 寄存器文件读取数据2
    
    // 输入：MEM阶段前推信号
    input [31:0] EX_MEM_ALU_result,     // MEM阶段ALU结果
    input [4:0] EX_MEM_WriteReg,        // MEM阶段写回寄存器地址
    input EX_MEM_RegWre,                // MEM阶段寄存器写使能
    
    // 输出：PC源选择
    output reg [1:0] PCSrc,             // PC源选择信号
    
    // 输出：前推后的数据（供其他模块使用）
    output reg [31:0] Branch_ReadData1, // 前推后的ReadData1
    output reg [31:0] Branch_ReadData2  // 前推后的ReadData2
);

    // 分支比较的前推逻辑
    always @(*) begin
        // 默认使用寄存器堆读出的值
        Branch_ReadData1 = ReadData1;
        Branch_ReadData2 = ReadData2;
        
        // MEM阶段前推到ID阶段（用于分支指令）
        if (EX_MEM_RegWre && EX_MEM_WriteReg != 0) begin
            if (EX_MEM_WriteReg == rs)
                Branch_ReadData1 = EX_MEM_ALU_result;
            if (EX_MEM_WriteReg == rt)
                Branch_ReadData2 = EX_MEM_ALU_result;
        end
    end
    
    // PCSrc生成逻辑
    always @(*) begin
        PCSrc = 2'b00;  // 默认：PC+4
        
        case(op)
            6'b111000: begin  // j指令
                PCSrc = 2'b11;  // 跳转到{PC[31:28], addr, 2'b00}
            end
            
            6'b111010: begin  // jal指令
                PCSrc = 2'b11;  // 跳转到{PC[31:28], addr, 2'b00}
            end
            
            6'b111001: begin  // jr指令
                PCSrc = 2'b10;  // 跳转到rs寄存器的值
            end
            
            6'b110100: begin  // beq指令
                // 在ID阶段比较rs和rt（使用前推后的值）
                if (Branch_ReadData1 == Branch_ReadData2) begin
                    PCSrc = 2'b01;  // 分支跳转：PC+4+offset*4
                end else begin
                    PCSrc = 2'b00;  // 不跳转：PC+4
                end
            end
            
            6'b110101: begin  // bne指令
                // 在ID阶段比较rs和rt（使用前推后的值）
                if (Branch_ReadData1 != Branch_ReadData2) begin
                    PCSrc = 2'b01;  // 分支跳转：PC+4+offset*4
                end else begin
                    PCSrc = 2'b00;  // 不跳转：PC+4
                end
            end
            
            6'b110110: begin  // bltz指令
                // 在ID阶段判断rs是否小于0（使用前推后的值）
                if (Branch_ReadData1[31] == 1) begin  // 符号位为1表示负数
                    PCSrc = 2'b01;  // 分支跳转：PC+4+offset*4
                end else begin
                    PCSrc = 2'b00;  // 不跳转：PC+4
                end
            end
            
            default: begin
                PCSrc = 2'b00;  // 默认：PC+4
            end
        endcase
    end

endmodule
