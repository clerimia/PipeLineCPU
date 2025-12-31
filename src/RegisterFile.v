`timescale 1ns / 1ps

//寄存器组
module RegisterFile(
        input CLK,                  // 时钟
        input [4:0] ReadReg1,       // rs寄存器地址输入端口
        input [4:0] ReadReg2,       // rt寄存器地址输入端口
        input [4:0] WriteReg,       // 写回寄存器地址
        input [31:0] WriteData,     // 写入寄存器的数据输入端口
        input RegWre,               // WE，写使能信号，为1时，在时钟边沿触发写入
        output reg[31:0] ReadData1, // rs寄存器数据输出端口
        output reg[31:0] ReadData2  // rt寄存器数据输出端口
    );
    
    initial begin
        ReadData1 <= 0;
        ReadData2 <= 0;
    end
   
    reg [31:0] regFile[0:31]; //  寄存器定义必须用reg类型
    integer i;
    initial begin
        for (i = 0; i < 32; i = i+ 1) regFile[i] <= 0;  
    end
    
    always@(ReadReg1 or ReadReg2 or RegWre or WriteReg or WriteData) 
    begin
        // 读取寄存器数据
        ReadData1 = regFile[ReadReg1];
        ReadData2 = regFile[ReadReg2];
        
        // 内部前推：如果正在写入的寄存器就是要读取的寄存器，直接前推
        // 这解决了同一周期内先写后读的问题
        if (RegWre && WriteReg != 0) begin
            if (ReadReg1 == WriteReg)
                ReadData1 = WriteData;
            if (ReadReg2 == WriteReg)
                ReadData2 = WriteData;
        end
    end
    
    always@(negedge CLK)
    begin
        // $0恒为0，所以写入寄存器的地址不能为0
        if(RegWre && WriteReg != 0)
            begin
                regFile[WriteReg] <= WriteData;
            end
    end
endmodule
