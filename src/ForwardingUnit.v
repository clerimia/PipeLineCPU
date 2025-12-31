`timescale 1ns / 1ps

// 前推单元（数据转发单元）
// 功能：检测数据冒险并生成前推控制信号，将EX、MEM、WB阶段的结果前推到EX阶段
module ForwardingUnit(
    // EX阶段需要的源寄存器
    input [4:0] ID_EX_rs,           // EX阶段的源寄存器1
    input [4:0] ID_EX_rt,           // EX阶段的源寄存器2
    
    // MEM阶段的寄存器写回信息
    input [4:0] EX_MEM_WriteReg,    // MEM阶段要写回的寄存器
    input EX_MEM_RegWre,            // MEM阶段是否写寄存器
    
    // WB阶段的寄存器写回信息
    input [4:0] MEM_WB_WriteReg,    // WB阶段要写回的寄存器
    input MEM_WB_RegWre,            // WB阶段是否写寄存器
    
    // 前推控制信号输出
    output reg [1:0] ForwardA,      // ALU输入A的前推控制
    output reg [1:0] ForwardB       // ALU输入B的前推控制
);
    // ForwardA/B的取值：
    // 00: 不前推，使用寄存器堆的输出
    // 01: 从WB阶段前推
    // 10: 从MEM阶段前推

    initial begin
        ForwardA = 2'b00;
        ForwardB = 2'b00;
    end

    always @(*) begin
        // 默认值：不前推
        ForwardA = 2'b00;
        ForwardB = 2'b00;
        
        // ====================================================================
        // EX冒险：前一条指令在MEM阶段，当前指令在EX阶段
        // ====================================================================
        // 前推A输入
        if (EX_MEM_RegWre && 
            (EX_MEM_WriteReg != 0) && 
            (EX_MEM_WriteReg == ID_EX_rs)) begin
            ForwardA = 2'b10;  // 从MEM阶段前推
        end
        // MEM冒险：前面第二条指令在WB阶段，当前指令在EX阶段
        // 只有当EX冒险不发生时才考虑MEM冒险
        else if (MEM_WB_RegWre && 
                 (MEM_WB_WriteReg != 0) && 
                 (MEM_WB_WriteReg == ID_EX_rs)) begin
            ForwardA = 2'b01;  // 从WB阶段前推
        end
        
        // 前推B输入（逻辑与A相同）
        if (EX_MEM_RegWre && 
            (EX_MEM_WriteReg != 0) && 
            (EX_MEM_WriteReg == ID_EX_rt)) begin
            ForwardB = 2'b10;  // 从MEM阶段前推
        end
        else if (MEM_WB_RegWre && 
                 (MEM_WB_WriteReg != 0) && 
                 (MEM_WB_WriteReg == ID_EX_rt)) begin
            ForwardB = 2'b01;  // 从WB阶段前推
        end
    end

endmodule
