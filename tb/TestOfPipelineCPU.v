`timescale 1ns / 1ps

// 流水线CPU测试模块
module TestOfPipelineCPU();
    // 基本输入：时钟和复位
    reg CLK;
    reg RST;
    
    // 输出信号
    wire [31:0] curPC;
    wire [31:0] IF_PC;
    wire [31:0] IF_instruction;
    wire [31:0] ID_PC;
    wire [31:0] ID_instruction;
    wire [5:0] ID_op;
    wire [4:0] ID_rs;
    wire [4:0] ID_rt;
    wire [4:0] ID_rd;
    wire [31:0] EX_ALU_result;
    wire [31:0] MEM_ALU_result;
    wire [31:0] WB_WriteData;
    wire [4:0] WB_WriteReg;
    wire WB_RegWre;
    
    // 周期计数器
    integer cycle_count = 0;
    
    // 实例化流水线CPU
    PipelineCPU uut (
        .CLK(CLK),
        .RST(RST),
        .curPC(curPC),
        .IF_PC(IF_PC),
        .IF_instruction(IF_instruction),
        .ID_PC(ID_PC),
        .ID_instruction(ID_instruction),
        .ID_op(ID_op),
        .ID_rs(ID_rs),
        .ID_rt(ID_rt),
        .ID_rd(ID_rd),
        .EX_ALU_result(EX_ALU_result),
        .MEM_ALU_result(MEM_ALU_result),
        .WB_WriteData(WB_WriteData),
        .WB_WriteReg(WB_WriteReg),
        .WB_RegWre(WB_RegWre)
    );
    
    // 时钟生成
    initial begin

        CLK = 0;
        RST = 0;

        // 复位20ns后开始
        #20 RST = 1;

        // 时钟周期40ns（频率25MHz）
        forever #20 CLK = ~CLK;
    end

    // 周期计数
    always @(posedge CLK) begin
        if (RST) cycle_count <= cycle_count + 1;
    end

    // 详细监控输出
    always @(posedge CLK) begin
        if (RST) begin
            $display("\n========== Cycle %0d ==========" , cycle_count);
            $display("[IF]  PC=%h  Inst=%h", curPC, IF_instruction);
            $display("[ID]  PC=%h  Inst=%h  op=%b  rs=$%0d  rt=$%0d",
                     ID_PC, ID_instruction, ID_op, ID_rs, ID_rt);
            $display("[EX]  ALU_result=%h", EX_ALU_result);
            $display("[WB]  Reg=$%0d  Data=%h  En=%b", WB_WriteReg, WB_WriteData, WB_RegWre);

            // 显示流水线控制信号
            $display("[CTL] PC_Write=%b  IF_ID_Write=%b  IF_Flush=%b  ID_EX_Flush=%b  PCSrc=%b",
                     uut.PC_Write, uut.IF_ID_Write, uut.IF_Flush, uut.ID_EX_Flush, uut.PCSrc);

            // 显示关键寄存器值
            $display("[REG] $1=%0d  $2=%0d  $3=%0d  $4=%0d  $5=%0d  $6=%0d",
                     uut.RegisterFile_inst.regFile[1],
                     uut.RegisterFile_inst.regFile[2],
                     uut.RegisterFile_inst.regFile[3],
                     uut.RegisterFile_inst.regFile[4],
                     uut.RegisterFile_inst.regFile[5],
                     uut.RegisterFile_inst.regFile[6]);

            // 显示分支比较信息（当是分支指令时）
            if (ID_op == 6'b110100 || ID_op == 6'b110101 || ID_op == 6'b110110) begin
                $display("[BRN] ReadData1=%h  ReadData2=%h  Branch=%s",
                         uut.ReadData1, uut.ReadData2,
                         (uut.PCSrc != 2'b00) ? "TAKEN" : "NOT_TAKEN");
            end

            // 检测停机指令 halt
            if (ID_op == 6'b111111) begin
                // 在仿真结束前显示最终结果
                $display("\n检测到停机指令，仿真结束。");
                $display("\n\n========================================");
                $display("           仿真结束 - 最终结果");
                $display("========================================");
                $display("总共运行 %0d 个时钟周期", cycle_count);

                $display("\n===== 寄存器状态 =====");
                $display("$1  (n)       = %0d (0x%h)", uut.RegisterFile_inst.regFile[1], uut.RegisterFile_inst.regFile[1]);
                $display("$2  (fib_prev)= %0d (0x%h)", uut.RegisterFile_inst.regFile[2], uut.RegisterFile_inst.regFile[2]);
                $display("$3  (fib_cur) = %0d (0x%h)", uut.RegisterFile_inst.regFile[3], uut.RegisterFile_inst.regFile[3]);
                $display("$4  (i)       = %0d (0x%h)", uut.RegisterFile_inst.regFile[4], uut.RegisterFile_inst.regFile[4]);
                $display("$5  (cmp)     = %0d (0x%h)", uut.RegisterFile_inst.regFile[5], uut.RegisterFile_inst.regFile[5]);
                $display("$6  (temp)    = %0d (0x%h)", uut.RegisterFile_inst.regFile[6], uut.RegisterFile_inst.regFile[6]);
                $display("$7  (result)  = %0d (0x%h)", uut.RegisterFile_inst.regFile[7], uut.RegisterFile_inst.regFile[7]);

                $display("\n===== 数据内存内容 =====");
                $display("MEM[0] = %0d (0x%h)",
                         {uut.DataMEM_inst.ram[0], uut.DataMEM_inst.ram[1],
                          uut.DataMEM_inst.ram[2], uut.DataMEM_inst.ram[3]},
                         {uut.DataMEM_inst.ram[0], uut.DataMEM_inst.ram[1],
                          uut.DataMEM_inst.ram[2], uut.DataMEM_inst.ram[3]});

                $display("\n===== 验证结果 =====");
                if (uut.RegisterFile_inst.regFile[3] == 55) begin
                    $display("*** 成功! Fib(10) = 55 ***");
                end else begin
                    $display("*** 失败! 期望 Fib(10)=55, 实际 $3=%0d ***",
                             uut.RegisterFile_inst.regFile[3]);
                end
                $display("========================================\n");

                $display("========================================");
                $display("           流水线CPU作者");
                $display("========================================");
                $display("1. 2022217375  计科23-2班 任怡霖");
                $display("2. 2023217316  计科23-2班 徐锦浩");
                $display("========================================");
                $finish;
            end
        end
    end
    
endmodule
