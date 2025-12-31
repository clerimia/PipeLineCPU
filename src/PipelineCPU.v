`timescale 1ns / 1ps

// 五级流水线CPU
// 功能：实现MIPS指令集的五级流水线，支持冲突检测和数据前推
module PipelineCPU(
    input CLK,                  // 时钟信号
    input RST,                  // 复位信号
    
    // 调试输出信号
    output [31:0] curPC,        // 当前PC值
    output [31:0] IF_PC,        // IF阶段PC
    output [31:0] IF_instruction, // IF阶段指令
    output [31:0] ID_PC,        // ID阶段PC
    output [31:0] ID_instruction, // ID阶段指令
    output [5:0] ID_op,         // ID阶段操作码
    output [4:0] ID_rs,
    output [4:0] ID_rt,
    output [4:0] ID_rd,
    output [31:0] EX_ALU_result, // EX阶段ALU结果
    output [31:0] MEM_ALU_result, // MEM阶段ALU结果
    output [31:0] WB_WriteData, // WB阶段写回数据
    output [4:0] WB_WriteReg,   // WB阶段写回寄存器
    output WB_RegWre            // WB阶段寄存器写使能
);

    // ========================================================================
    // 内部信号定义
    // ========================================================================
    
    // PC相关
    wire [31:0] nextPC;
    wire PC_Write;              // 流水线暂停控制
    wire PCWre;
    reg [1:0] PCSrc;            // PC源选择控制
    
    // IF/ID流水线寄存器信号
    wire IF_ID_Write;
    wire IF_Flush_hazard;        // 来自冒险检测单元的flush
    wire IF_Flush;               // 最终的flush信号
    wire [31:0] IF_ID_PC;
    wire [31:0] IF_ID_instruction;
    wire [31:0] IF_instruction_internal;  // 内部指令信号
    
    // 分支跳转时的flush（只有当分支实际跳转且没有暂停时才清空）
    wire is_branch_op;
    wire branch_taken_flush;
    assign is_branch_op = (ID_op == 6'b110100) || (ID_op == 6'b110101) || (ID_op == 6'b110110);
    assign branch_taken_flush = is_branch_op && (PCSrc != 2'b00) && PC_Write;
    assign IF_Flush = IF_Flush_hazard | branch_taken_flush;
    
    // ID阶段信号
    wire [4:0] sa;
    wire [15:0] immediate;
    wire [25:0] addr;
    wire [31:0] extend;
    wire [31:0] ReadData1, ReadData2;
    wire RegWre_ID, ALUSrcA_ID, ALUSrcB_ID, mRD_ID, mWR_ID, DBDataSrc_ID, WrRegDSrc_ID, ExtSel_ID;
    wire [1:0] RegDst_ID;
    wire [2:0] ALUOp_ID;
    
    // ID/EX流水线寄存器信号
    wire ID_EX_Flush;
    wire [31:0] ID_EX_PC, ID_EX_ReadData1, ID_EX_ReadData2, ID_EX_extend;
    wire [4:0] ID_EX_rs, ID_EX_rt, ID_EX_rd, ID_EX_sa;
    wire ID_EX_RegWre, ID_EX_ALUSrcA, ID_EX_ALUSrcB, ID_EX_mRD, ID_EX_mWR, ID_EX_DBDataSrc, ID_EX_WrRegDSrc;
    wire [1:0] ID_EX_RegDst;
    wire [2:0] ID_EX_ALUOp;
    
    // EX阶段信号
    wire [31:0] ALU_result;
    wire ALU_zero;
    wire [1:0] ForwardA, ForwardB;
    wire [4:0] EX_WriteReg;
    wire [31:0] ALU_InputA, ALU_InputB;  // 前推后的ALU输入
    
    // EX/MEM流水线寄存器信号
    wire [31:0] EX_MEM_ALU_result, EX_MEM_ReadData2;
    wire [4:0] EX_MEM_WriteReg;
    wire EX_MEM_RegWre, EX_MEM_mRD, EX_MEM_mWR, EX_MEM_DBDataSrc, EX_MEM_WrRegDSrc, EX_MEM_zero;
    
    // MEM阶段信号
    wire [31:0] MemData;
    
    // MEM/WB流水线寄存器信号
    wire [31:0] MEM_WB_MemData, MEM_WB_ALU_result;
    wire [4:0] MEM_WB_WriteReg;
    wire MEM_WB_RegWre, MEM_WB_DBDataSrc, MEM_WB_WrRegDSrc;
    
    // 赋值输出端口
    assign curPC = IF_PC;
    assign IF_instruction = IF_instruction_internal;  // 使用内部信号
    assign ID_PC = IF_ID_PC;
    assign ID_instruction = IF_ID_instruction;
    assign ID_op = IF_ID_instruction[31:26];
    assign ID_rs = IF_ID_instruction[25:21];
    assign ID_rt = IF_ID_instruction[20:16];
    assign ID_rd = IF_ID_instruction[15:11];
    assign EX_ALU_result = ALU_result;
    assign MEM_ALU_result = EX_MEM_ALU_result;
    assign WB_WriteReg = MEM_WB_WriteReg;
    assign WB_RegWre = MEM_WB_RegWre;
    
    // 默认PCWre为1（流水线始终运行，除非halt）
    assign PCWre = (ID_op != 6'b111111) ? 1 : 0;
    
    // ========================================================================
    // PCSrc生成逻辑（在ID阶段判断分支/跳转）
    // ========================================================================
    // ID阶段分支比较的前推逻辑
    reg [31:0] Branch_ReadData1, Branch_ReadData2;
    
    always @(*) begin
        // 默认使用寄存器堆读出的值
        Branch_ReadData1 = ReadData1;
        Branch_ReadData2 = ReadData2;
        
        // MEM阶段前推到ID阶段（用于分支指令）
        if (EX_MEM_RegWre && EX_MEM_WriteReg != 0) begin
            if (EX_MEM_WriteReg == ID_rs)
                Branch_ReadData1 = EX_MEM_ALU_result;
            if (EX_MEM_WriteReg == ID_rt)
                Branch_ReadData2 = EX_MEM_ALU_result;
        end
    end
    
    always @(*) begin
        PCSrc = 2'b00;  // 默认：PC+4
        
        case(ID_op)
            6'b111000: begin  // j指令
                PCSrc = 2'b11;  // 跳转到{PC[31:28], addr, 2'b00}
            end
            
            6'b111010: begin  // jal指令
                PCSrc = 2'b11;  // 跳转到{PC[31:28], addr, 2'b00}
            end
            
            6'b111001: begin  // jr指令
                PCSrc = 2'b10;  // 跳转到rs寄存器的值
            end
            
            6'b110100: begin  // beq指令
                // 在ID阶段比较rs和rt（使用前推后的值）
                if (Branch_ReadData1 == Branch_ReadData2) begin
                    PCSrc = 2'b01;  // 分支跳转：PC+4+offset*4
                end else begin
                    PCSrc = 2'b00;  // 不跳转：PC+4
                end
            end
            
            6'b110101: begin  // bne指令
                // 在ID阶段比较rs和rt（使用前推后的值）
                if (Branch_ReadData1 != Branch_ReadData2) begin
                    PCSrc = 2'b01;  // 分支跳转：PC+4+offset*4
                end else begin
                    PCSrc = 2'b00;  // 不跳转：PC+4
                end
            end
            
            6'b110110: begin  // bltz指令
                // 在ID阶段判断rs是否小于0（使用前推后的值）
                if (Branch_ReadData1[31] == 1) begin  // 符号位为1表示负数
                    PCSrc = 2'b01;  // 分支跳转：PC+4+offset*4
                end else begin
                    PCSrc = 2'b00;  // 不跳转：PC+4
                end
            end
            
            default: begin
                PCSrc = 2'b00;  // 默认：PC+4
            end
        endcase
    end

    // ========================================================================
    // 1. 取指阶段 (IF - Instruction Fetch)
    // ========================================================================
    
    // PC寄存器
    PC PC_inst(
        .CLK(CLK),
        .RST(RST),
        .PCWre(PCWre),
        .PC_Write(PC_Write),
        .nextPC(nextPC),
        .curPC(IF_PC)
    );
    
    // 指令存储器
    InsMEM InsMEM_inst(
        .IAddr(IF_PC),
        .InsMemRW(1'b1),  // 始终读指令
        .IDataOut(IF_instruction_internal)  // 输出到内部信号
    );
    
    // IF/ID流水线寄存器
    IF_ID_Register IF_ID_reg(
        .CLK(CLK),
        .RST(RST),
        .IF_ID_Write(IF_ID_Write),
        .IF_Flush(IF_Flush),
        .PC_in(IF_PC),
        .instruction_in(IF_instruction_internal),  // 使用内部信号
        .PC_out(IF_ID_PC),
        .instruction_out(IF_ID_instruction)
    );

    // ========================================================================
    // 2. 译码阶段 (ID - Instruction Decode)
    // ========================================================================
    
    // 指令分割
    InstructionCut InstructionCut_inst(
        .instruction(IF_ID_instruction),
        .op(ID_op),
        .rs(ID_rs),
        .rt(ID_rt),
        .rd(ID_rd),
        .sa(sa),
        .immediate(immediate),
        .addr(addr)
    );
    
    // 控制单元
    PipelineControlUnit ControlUnit_inst(
        .op(ID_op),
        .RegWre(RegWre_ID),
        .RegDst(RegDst_ID),
        .ALUSrcA(ALUSrcA_ID),
        .ALUSrcB(ALUSrcB_ID),
        .ALUOp(ALUOp_ID),
        .mRD(mRD_ID),
        .mWR(mWR_ID),
        .DBDataSrc(DBDataSrc_ID),
        .WrRegDSrc(WrRegDSrc_ID),
        .ExtSel(ExtSel_ID)
    );
    
    // 寄存器堆
    RegisterFile RegisterFile_inst(
        .CLK(CLK),
        .ReadReg1(ID_rs),
        .ReadReg2(ID_rt),
        .WriteReg(MEM_WB_WriteReg),
        .WriteData(WB_WriteData),
        .RegWre(MEM_WB_RegWre),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );
    
    // 立即数扩展
    SignZeroExtend SignZeroExtend_inst(
        .immediate(immediate),
        .ExtSel(ExtSel_ID),
        .extendImmediate(extend)
    );
    
    // ID/EX流水线寄存器
    ID_EX_Register ID_EX_reg(
        .CLK(CLK),
        .RST(RST),
        .ID_EX_Flush(ID_EX_Flush),
        // 控制信号
        .RegWre_in(RegWre_ID),
        .RegDst_in(RegDst_ID),
        .ALUSrcA_in(ALUSrcA_ID),
        .ALUSrcB_in(ALUSrcB_ID),
        .ALUOp_in(ALUOp_ID),
        .mRD_in(mRD_ID),
        .mWR_in(mWR_ID),
        .DBDataSrc_in(DBDataSrc_ID),
        .WrRegDSrc_in(WrRegDSrc_ID),
        // 数据
        .PC_in(IF_ID_PC),
        .ReadData1_in(ReadData1),
        .ReadData2_in(ReadData2),
        .extend_in(extend),
        .rs_in(ID_rs),
        .rt_in(ID_rt),
        .rd_in(ID_rd),
        .sa_in(sa),
        // 输出
        .RegWre_out(ID_EX_RegWre),
        .RegDst_out(ID_EX_RegDst),
        .ALUSrcA_out(ID_EX_ALUSrcA),
        .ALUSrcB_out(ID_EX_ALUSrcB),
        .ALUOp_out(ID_EX_ALUOp),
        .mRD_out(ID_EX_mRD),
        .mWR_out(ID_EX_mWR),
        .DBDataSrc_out(ID_EX_DBDataSrc),
        .WrRegDSrc_out(ID_EX_WrRegDSrc),
        .PC_out(ID_EX_PC),
        .ReadData1_out(ID_EX_ReadData1),
        .ReadData2_out(ID_EX_ReadData2),
        .extend_out(ID_EX_extend),
        .rs_out(ID_EX_rs),
        .rt_out(ID_EX_rt),
        .rd_out(ID_EX_rd),
        .sa_out(ID_EX_sa)
    );

    // ========================================================================
    // 3. 执行阶段 (EX - Execute)
    // ========================================================================
    
    // 写寄存器地址选择
    WriteRegSelector WriteRegSelector_EX(
        .RegDst(ID_EX_RegDst),
        .rt(ID_EX_rt),
        .rd(ID_EX_rd),
        .WriteReg(EX_WriteReg)
    );
    
    // 前推单元
    ForwardingUnit ForwardingUnit_inst(
        .ID_EX_rs(ID_EX_rs),
        .ID_EX_rt(ID_EX_rt),
        .EX_MEM_WriteReg(EX_MEM_WriteReg),
        .EX_MEM_RegWre(EX_MEM_RegWre),
        .MEM_WB_WriteReg(MEM_WB_WriteReg),
        .MEM_WB_RegWre(MEM_WB_RegWre),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );
    
    // ALU
    ALU ALU_inst(
        .ALUSrcA(ID_EX_ALUSrcA),
        .ALUSrcB(ID_EX_ALUSrcB),
        .ReadData1(ID_EX_ReadData1),
        .ReadData2(ID_EX_ReadData2),
        .sa(ID_EX_sa),
        .extend(ID_EX_extend),
        .ALUOp(ID_EX_ALUOp),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .MEM_ForwardData(EX_MEM_ALU_result),
        .WB_ForwardData(WB_WriteData),
        .zero(ALU_zero),
        .result(ALU_result)
    );
    
    // EX/MEM流水线寄存器
    EX_MEM_Register EX_MEM_reg(
        .CLK(CLK),
        .RST(RST),
        .RegWre_in(ID_EX_RegWre),
        .mRD_in(ID_EX_mRD),
        .mWR_in(ID_EX_mWR),
        .DBDataSrc_in(ID_EX_DBDataSrc),
        .WrRegDSrc_in(ID_EX_WrRegDSrc),
        .ALU_result_in(ALU_result),
        .ReadData2_in(ID_EX_ReadData2),
        .WriteReg_in(EX_WriteReg),
        .zero_in(ALU_zero),
        .RegWre_out(EX_MEM_RegWre),
        .mRD_out(EX_MEM_mRD),
        .mWR_out(EX_MEM_mWR),
        .DBDataSrc_out(EX_MEM_DBDataSrc),
        .WrRegDSrc_out(EX_MEM_WrRegDSrc),
        .ALU_result_out(EX_MEM_ALU_result),
        .ReadData2_out(EX_MEM_ReadData2),
        .WriteReg_out(EX_MEM_WriteReg),
        .zero_out(EX_MEM_zero)
    );

    // ========================================================================
    // 4. 访存阶段 (MEM - Memory Access)
    // ========================================================================
    
    // 数据存储器
    DataMEM DataMEM_inst(
        .mRD(EX_MEM_mRD),
        .mWR(EX_MEM_mWR),
        .DBDataSrc(EX_MEM_DBDataSrc),
        .DAddr(EX_MEM_ALU_result),
        .DataIn(EX_MEM_ReadData2),
        .DataOut(MemData),
        .DB()  // 不使用DB输出
    );
    
    // MEM/WB流水线寄存器
    MEM_WB_Register MEM_WB_reg(
        .CLK(CLK),
        .RST(RST),
        .RegWre_in(EX_MEM_RegWre),
        .DBDataSrc_in(EX_MEM_DBDataSrc),
        .WrRegDSrc_in(EX_MEM_WrRegDSrc),
        .MemData_in(MemData),
        .ALU_result_in(EX_MEM_ALU_result),
        .WriteReg_in(EX_MEM_WriteReg),
        .RegWre_out(MEM_WB_RegWre),
        .DBDataSrc_out(MEM_WB_DBDataSrc),
        .WrRegDSrc_out(MEM_WB_WrRegDSrc),
        .MemData_out(MEM_WB_MemData),
        .ALU_result_out(MEM_WB_ALU_result),
        .WriteReg_out(MEM_WB_WriteReg)
    );

    // ========================================================================
    // 5. 写回阶段 (WB - Write Back)
    // ========================================================================
    
    // 写回数据选择
    assign WB_WriteData = MEM_WB_DBDataSrc ? MEM_WB_MemData : MEM_WB_ALU_result;
    
    // ========================================================================
    // 冲突检测单元
    // ========================================================================
    
    HazardDetectionUnit HazardDetectionUnit_inst(
        .ID_rs(ID_rs),
        .ID_rt(ID_rt),
        .ID_op(ID_op),
        .EX_rt(ID_EX_rt),
        .EX_WriteReg(EX_WriteReg),
        .EX_mRD(ID_EX_mRD),
        .EX_RegWre(ID_EX_RegWre),
        .MEM_WriteReg(EX_MEM_WriteReg),
        .MEM_RegWre(EX_MEM_RegWre),
        .PC_Write(PC_Write),
        .IF_ID_Write(IF_ID_Write),
        .IF_Flush(IF_Flush_hazard),   // 连接到hazard信号，最终IF_Flush由组合逻辑生成
        .ID_EX_Flush(ID_EX_Flush)
    );
    
    // ========================================================================
    // PC计算单元
    // ========================================================================
    // PC选择：分支指令使用ID阶段PC，其他情况使用IF阶段PC
    wire [31:0] pcAdd_curPC;
    assign pcAdd_curPC = (PCSrc == 2'b01) ? IF_ID_PC : IF_PC;
    
    pcAdd pcAdd_inst(
        .RST(RST),
        .PCSrc(PCSrc),
        .immediate(extend),
        .addr(addr),
        .curPC(pcAdd_curPC),
        .rs(ReadData1),
        .nextPC(nextPC)
    );

endmodule
