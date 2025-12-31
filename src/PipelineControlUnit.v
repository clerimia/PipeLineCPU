`timescale 1ns / 1ps

// 流水线控制单元
// 功能：根据指令操作码生成控制信号（简化版本，不需要状态机）
module PipelineControlUnit(
    input [5:0] op,              // 指令操作码
    
    // 控制信号输出
    output reg RegWre,           // 寄存器写使能
    output reg [1:0] RegDst,     // 写寄存器地址选择
    output reg ALUSrcA,          // ALU输入A选择
    output reg ALUSrcB,          // ALU输入B选择
    output reg [2:0] ALUOp,      // ALU操作选择
    output reg mRD,              // 数据存储器读使能
    output reg mWR,              // 数据存储器写使能
    output reg DBDataSrc,        // 写回数据选择
    output reg WrRegDSrc,        // 写寄存器数据源选择
    output reg ExtSel            // 立即数扩展方式选择
);

    initial begin
        RegWre = 0;
        RegDst = 0;
        ALUSrcA = 0;
        ALUSrcB = 0;
        ALUOp = 0;
        mRD = 0;
        mWR = 0;
        DBDataSrc = 0;
        WrRegDSrc = 0;
        ExtSel = 0;
    end

    always @(*) begin
        // 默认值
        RegWre = 0;
        RegDst = 2'b00;
        ALUSrcA = 0;
        ALUSrcB = 0;
        ALUOp = 3'b000;
        mRD = 0;
        mWR = 0;
        DBDataSrc = 0;
        WrRegDSrc = 1;
        ExtSel = 0;
        
        case(op)
            // R型指令
            6'b000000: begin  // add
                RegWre = 1;
                RegDst = 2'b10;  // rd
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b000;
                WrRegDSrc = 1;
            end
            
            6'b000001: begin  // sub
                RegWre = 1;
                RegDst = 2'b10;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b001;
                WrRegDSrc = 1;
            end
            
            6'b010000: begin  // or
                RegWre = 1;
                RegDst = 2'b10;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b101;
                WrRegDSrc = 1;
            end
            
            6'b010001: begin  // and
                RegWre = 1;
                RegDst = 2'b10;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b110;
                WrRegDSrc = 1;
            end
            
            6'b011000: begin  // sll
                RegWre = 1;
                RegDst = 2'b10;
                ALUSrcA = 1;  // 使用sa
                ALUSrcB = 0;
                ALUOp = 3'b100;
                WrRegDSrc = 1;
            end
            
            6'b100110: begin  // slt
                RegWre = 1;
                RegDst = 2'b10;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b011;
                WrRegDSrc = 1;
            end
            
            // I型指令
            6'b000010: begin  // addi
                RegWre = 1;
                RegDst = 2'b01;  // rt
                ALUSrcA = 0;
                ALUSrcB = 1;  // 使用立即数
                ALUOp = 3'b000;
                ExtSel = 1;  // 符号扩展
                WrRegDSrc = 1;
            end
            
            6'b010010: begin  // ori
                RegWre = 1;
                RegDst = 2'b01;
                ALUSrcA = 0;
                ALUSrcB = 1;
                ALUOp = 3'b101;
                ExtSel = 0;  // 零扩展
                WrRegDSrc = 1;
            end
            
            6'b100111: begin  // sltiu
                RegWre = 1;
                RegDst = 2'b01;
                ALUSrcA = 0;
                ALUSrcB = 1;
                ALUOp = 3'b010;
                ExtSel = 0;
                WrRegDSrc = 1;
            end
            
            // 访存指令
            6'b110001: begin  // lw
                RegWre = 1;
                RegDst = 2'b01;
                ALUSrcA = 0;
                ALUSrcB = 1;
                ALUOp = 3'b000;
                mRD = 1;  // 读存储器
                DBDataSrc = 1;  // 数据来自存储器
                ExtSel = 1;
                WrRegDSrc = 1;
            end
            
            6'b110000: begin  // sw
                RegWre = 0;  // 不写寄存器
                ALUSrcA = 0;
                ALUSrcB = 1;
                ALUOp = 3'b000;
                mWR = 1;  // 写存储器
                ExtSel = 1;
            end
            
            6'b110100: begin  // beq
                RegWre = 0;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b001;  // 减法比较
                ExtSel = 1;
            end
            
            6'b110101: begin  // bne
                RegWre = 0;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b001;  // 减法比较
                ExtSel = 1;
            end
            
            6'b110110: begin  // bltz
                RegWre = 0;
                ALUSrcA = 0;
                ALUSrcB = 0;
                ALUOp = 3'b001;
                ExtSel = 1;
            end
            
            6'b111000: begin  // j
                RegWre = 0;
            end
            
            6'b111010: begin  // jal
                RegWre = 1;
                RegDst = 2'b00;  // $31
                WrRegDSrc = 0;  // PC+4
            end
            
            6'b111001: begin  // jr
                RegWre = 0;
            end
            
            6'b111111: begin  // halt
                RegWre = 0;
            end
            
            default: begin
                // NOP或未定义指令
                RegWre = 0;
            end
        endcase
    end

endmodule
