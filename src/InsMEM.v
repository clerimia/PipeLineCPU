`timescale 1ns / 1ps

// 指令存储器模块
// 功能：从外部文件加载MIPS指令并根据地址输出32位指令
module InsMEM(
        input [31:0] IAddr,         // 指令地址输入
        input InsMemRW,             // 读写控制信号(1:读指令，0:写指令)
        output reg[31:0] IDataOut   // 指令数据输出
    );
    
    // 内部存储数组：8位宽，129个单元(地址0-128)，可存储32条完整指令
    reg [7:0] rom[128:0];  
    
    // 初始化：从MIPS.txt文件中读取十六进制指令并存储到rom数组
    initial 
    begin
       $readmemh("MIPS.txt", rom);
       IDataOut = 32'h00000000;  // 初始化输出为0
       
       // 调试信息：显示加载的指令
       $display("Loading MIPS.txt from: MIPS.txt");
       $display("First 8 bytes:");
       $display("rom[0] = 8'h%h", rom[0]);
       $display("rom[1] = 8'h%h", rom[1]);
       $display("rom[2] = 8'h%h", rom[2]);
       $display("rom[3] = 8'h%h", rom[3]);
       $display("rom[4] = 8'h%h", rom[4]);
       $display("rom[5] = 8'h%h", rom[5]);
       $display("rom[6] = 8'h%h", rom[6]);
       $display("rom[7] = 8'h%h", rom[7]);
    end
    
    // 指令读取逻辑：当地址或读写信号变化时执行
    always@(IAddr or InsMemRW)  
    begin
        // 当允许读指令时
        if(InsMemRW)    
            begin
                // 从rom中读取连续4个字节并组合成32位指令
                // 注意：MIPS指令是大端存储，高字节在前低字节在后
                IDataOut[7:0] = rom[IAddr + 3];   // 最低位字节
                IDataOut[15:8] = rom[IAddr + 2];  // 次低位字节
                IDataOut[23:16] = rom[IAddr + 1]; // 次高位字节
                IDataOut[31:24] = rom[IAddr];     // 最高位字节
                
                // 调试信息
                $display("Time=%0t | Reading Addr=%h: rom[%0d]=%h rom[%0d]=%h rom[%0d]=%h rom[%0d]=%h -> IDataOut=%h",
                         $time, IAddr, IAddr, rom[IAddr], IAddr+1, rom[IAddr+1], 
                         IAddr+2, rom[IAddr+2], IAddr+3, rom[IAddr+3], IDataOut);
            end
        else
            begin
                IDataOut = 32'h00000000;  // 不读取时输出0
            end
    end
    
endmodule
