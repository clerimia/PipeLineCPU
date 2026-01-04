`timescale 1ns / 1ps

module pcAdd(
        input RST,
        input [1:0] PCSrc,       //数据选择器输入
        input [31:0] immediate,  //偏移量
        input [25:0] addr,
        input [31:0] curPC,
        input [31:0] rs,
        output reg[31:0] nextPC  //新指令地址
    );
    
    initial begin
        nextPC = 0;
    end
    
    reg [31:0] pc;
    
    always@(*)
    begin
        if(!RST) begin
            nextPC = 0; // 复位
        end
        else begin
            pc = curPC + 4; // pc接受下一条指令地址
            case(PCSrc)
                2'b00: nextPC = pc;
                2'b01: nextPC = pc + (immediate << 2);
                2'b10: nextPC = rs;
                2'b11: nextPC = {pc[31:28],addr,2'b00}; // 4(PC对齐)+26(32-6)+2(固定对齐4的倍数)
            endcase
        end
    end
endmodule
