`timescale 1ns / 1ps

// ALU算术逻辑单元
// 功能：执行算术和逻辑运算，支持数据前推
module ALU(
        input ALUSrcA,
        input ALUSrcB,
        input [31:0] ReadData1,
        input [31:0] ReadData2,
        input [4:0] sa,
        input [31:0] extend,
        input [2:0] ALUOp,
        // 前推控制信号和数据
        input [1:0] ForwardA,
        input [1:0] ForwardB,
        input [31:0] MEM_ForwardData,  // 从MEM阶段前推的数据
        input [31:0] WB_ForwardData,   // 从WB阶段前推的数据
        output reg zero,
        output reg[31:0] result
    );
    
    reg [31:0] A;
    reg [31:0] B;
    
    initial begin
        result = 0;
        zero = 0;
    end
    
    always@(*) 
    begin
        // 根据前推信号选择ALU输入A
        case(ForwardA)
            2'b00: A = (ALUSrcA == 0) ? ReadData1 : sa;  // 不前推
            2'b01: A = WB_ForwardData;                    // 从WB前推
            2'b10: A = MEM_ForwardData;                   // 从MEM前推
            default: A = ReadData1;
        endcase
        
        // 根据前推信号选择ALU输入B
        case(ForwardB)
            2'b00: B = (ALUSrcB == 0) ? ReadData2 : extend;  // 不前推
            2'b01: B = WB_ForwardData;                       // 从WB前推
            2'b10: B = MEM_ForwardData;                      // 从MEM前推
            default: B = ReadData2;
        endcase
        
        // 对于立即数操作，强制使用extend
        if (ALUSrcB == 1) begin
            B = extend;
        end
        case(ALUOp)
            3'b000: result = A + B;
            3'b001: result = A - B;
            3'b010: result = (A < B) ? 1 : 0;
            3'b011: result = (((A < B) && (A[31] == B[31])) || ((A[31] == 1 && B[31] == 0))) ? 1 : 0;  // slt有符号比较
            3'b100: result = B << A;
            3'b101: result = A | B;
            3'b110: result = A & B;
            3'b111: result = A ^ B;
        endcase
        zero = (result == 0) ? 1 : 0;
    end 
endmodule
