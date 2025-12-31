`timescale 1ns / 1ps

module PC(
       input CLK,               // 时钟
       input RST,               // 是否重置地址。1-初始化PC，否则接受新地址
       input PCWre,             // 是否接受新的地址。0-不更改；1-可以更改
       input PC_Write,          // 流水线暂停控制（来自冲突检测单元）
       input [31:0] nextPC,     // 新指令地址
       output reg[31:0] curPC   // 当前指令的地址
    );
    
    initial begin
        curPC <= 0;
    end

    always@(posedge CLK or negedge RST)
    begin
        if(!RST) // Reset == 0, PC = 0
            begin
                curPC <= 0;
            end
        else 
            begin
                if(PCWre && PC_Write) // PCWre == 1 且 PC_Write == 1
                    begin 
                        curPC <= nextPC;
                    end
                else    // PCWre == 0 或 PC_Write == 0, halt 或流水线暂停
                    begin
                        curPC <= curPC;
                    end
            end
    end
endmodule
