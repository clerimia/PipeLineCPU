`timescale 1ns / 1ps

// 写寄存器地址选择器
// 功能：根据RegDst信号选择写回的目标寄存器地址
module WriteRegSelector(
    input [1:0] RegDst,          // 寄存器地址选择信号
    input [4:0] rt,              // rt寄存器地址(I型指令)
    input [4:0] rd,              // rd寄存器地址(R型指令)
    output reg [4:0] WriteReg    // 输出：目标寄存器地址
);

    always @(*) begin
        case(RegDst)
            2'b00: WriteReg = 5'd31;     // jal指令，写入$31
            2'b01: WriteReg = rt;        // I型指令，写入rt
            2'b10: WriteReg = rd;        // R型指令，写入rd
            default: WriteReg = 5'd0;    // 默认值
        endcase
    end

endmodule
