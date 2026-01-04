`timescale 1ns / 1ps

// 冲突检测单元
// 功能：检测数据冒险和控制冒险，生成暂停和清空信号
module HazardDetectionUnit(
    // ID阶段的寄存器
    input [4:0] ID_rs,              // ID阶段的源寄存器1
    input [4:0] ID_rt,              // ID阶段的源寄存器2
    input [5:0] ID_op,              // ID阶段的操作码
    
    // EX阶段的信息
    input [4:0] EX_rt,              // EX阶段的rt
    input [4:0] EX_WriteReg,        // EX阶段的写寄存器
    input EX_mRD,                   // EX阶段是否为load指令
    input EX_RegWre,                // EX阶段是否写寄存器
    
    // MEM阶段的信息（用于分支指令的数据冒险检测）
    input [4:0] MEM_WriteReg,       // MEM阶段的写寄存器
    input MEM_RegWre,               // MEM阶段是否写寄存器
    input MEM_mRD,                  // MEM阶段是否为load指令
    
    // 输出控制信号
    output reg PC_Write,            // PC写使能（为0时暂停）
    output reg IF_ID_Write,         // IF/ID寄存器写使能（为0时暂停）
    output reg IF_Flush,            // IF阶段清空信号
    output reg ID_EX_Flush          // ID/EX阶段清空信号（插入气泡）
);

    initial begin
        PC_Write = 1;
        IF_ID_Write = 1;
        IF_Flush = 0;
        ID_EX_Flush = 0;
    end

    // 判断是否为分支指令
    wire is_branch;
    assign is_branch = (ID_op == 6'b110100) ||  // beq
                       (ID_op == 6'b110101) ||  // bne
                       (ID_op == 6'b110110);    // bltz

    always @(*) begin
        // 默认情况下，不暂停，不插入气泡
        PC_Write = 1;
        IF_ID_Write = 1;
        IF_Flush = 0;
        ID_EX_Flush = 0;
        
        // ========================================================================
        // 1. Load-Use数据冒险检测
        // ========================================================================
        // EX阶段是Load指令，ID阶段指令需要使用Load的结果
        if (EX_mRD && EX_RegWre && EX_WriteReg != 0) begin
            if ((EX_WriteReg == ID_rs && ID_rs != 0) || 
                (EX_WriteReg == ID_rt && ID_rt != 0)) begin
                // 暂停流水线，插入气泡
                PC_Write = 0;
                IF_ID_Write = 0;
                ID_EX_Flush = 1;
            end
        end
        // 注意：上面的Load-Use检测对所有指令生效（包括分支指令）
        // 如果分支指令遇到Load-Use，会先暂停1周期
        // 然后在下个周期进入下面的分支冒险检测（此时Load在MEM阶段）
        
        // ========================================================================
        // 2. 分支指令的数据冒险检测
        // ========================================================================
        else if (is_branch) begin
            // 2.1 检测EX阶段的普通数据冒险
            // EX阶段的指令（非Load）会写入分支需要的寄存器
            if (EX_RegWre && EX_WriteReg != 0 && 
                ((EX_WriteReg == ID_rs) || 
                 ((ID_op == 6'b110100 || ID_op == 6'b110101) && EX_WriteReg == ID_rt))) begin
                // 暂停流水线，插入气泡
                PC_Write = 0;
                IF_ID_Write = 0;
                ID_EX_Flush = 1;
            end
            // 2.2 检测MEM阶段的Load指令数据冒险
            // Load指令在MEM阶段，数据刚从内存读出，无法前推到ID的分支判断
            else if (MEM_mRD && MEM_RegWre && MEM_WriteReg != 0 && 
                     ((MEM_WriteReg == ID_rs) || 
                      ((ID_op == 6'b110100 || ID_op == 6'b110101) && MEM_WriteReg == ID_rt))) begin
                // 继续暂停流水线（Load后接分支的第2次暂停）
                PC_Write = 0;
                IF_ID_Write = 0;
                ID_EX_Flush = 1;
            end
        end
        
        // ========================================================================
        // 3. 控制冒险：无条件跳转指令
        // ========================================================================
        // 跳转指令：j, jal, jr - 这些总是跳转，需要清空IF阶段
        if (ID_op == 6'b111000 || ID_op == 6'b111010 || ID_op == 6'b111001) begin
            IF_Flush = 1;
        end
        
        // 注意：条件分支指令（beq, bne, bltz）的IF_Flush由PipelineCPU根据PCSrc决定
        // 只有当分支实际跳转时才清空，否则下一条指令正常执行
        
        // ========================================================================
        // 4. halt指令：停止程序
        // ========================================================================
        if (ID_op == 6'b111111) begin
            PC_Write = 0;
            IF_ID_Write = 0;
        end
    end

endmodule
