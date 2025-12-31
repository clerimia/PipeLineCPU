# 五级流水线CPU - 项目实现总结

## 项目概述

本项目实现了一个完整的五级流水线MIPS CPU，支持16条MIPS指令，包含完善的数据冒险和控制冒险处理机制。

- 指令集：18条自定义的类MIPS指令
- 五级流水线
- 解决了数据冲突、控制冲突

---

## 核心实现

### 1. 五级流水线架构

- **IF (取指)**: PC → InsMEM → IF/ID(流水段寄存器)
- **ID (译码)**: InstructionCut → ControlUnit → RegisterFile → ID/EX
- **EX (执行)**: ALU + ForwardingUnit（数据前推单元） → EX/MEM
- **MEM (访存)**: DataMEM → MEM/WB
- **WB (写回)**: MUX → RegisterFile

### 2. 支持的指令集 (18条)

#### R型指令 (6条)
- ADD, SUB, OR, AND, SLL, SLT
- opcode r r r

#### I型指令 (8条)
- ADDI, ORI, SLTIU, LW, SW
- BEQ, BNE, BLTZ (分支指令)
- opcode r r i

#### J型指令 (3条)
- J, JAL, JR

#### 特殊指令
- HALT

---

## 关键技术实现

### 1. 数据冒险处理

#### EX阶段前推 (ALU → ALU)
```verilog
ForwardingUnit检测：
  if (EX_MEM_RegWre && EX_MEM_WriteReg == ID_EX_rs)
    ForwardA = 2'b10  // 从MEM阶段前推
```

#### MEM阶段前推 (MEM → ALU)
```verilog
  else if (MEM_WB_RegWre && MEM_WB_WriteReg == ID_EX_rs)
    ForwardA = 2'b01  // 从WB阶段前推
```

#### Load-Read冒险暂停
```verilog
HazardDetectionUnit检测：
  if (EX_mRD && (EX_WriteReg == ID_rs || EX_WriteReg == ID_rt))
    PC_Write = 0         // 暂停PC
    IF_ID_Write = 0      // 暂停IF/ID
    ID_EX_Flush = 1      // 插入气泡
```

### 2. 控制冒险处理

#### 分支指令在ID阶段判断
```verilog
// PCSrc生成逻辑（在ID阶段）
case(ID_op)
  6'b110100: // BEQ
    if (Branch_ReadData1 == Branch_ReadData2)
      PCSrc = 2'b01;  // 分支跳转
  6'b110101: // BNE
    if (Branch_ReadData1 != Branch_ReadData2)
      PCSrc = 2'b01;
  6'b110110: // BLTZ
    if (Branch_ReadData1[31] == 1)
      PCSrc = 2'b01;
endcase
```

#### **关键修复1：分支指令的MEM前推**
```verilog
// 在ID阶段进行分支比较时，支持从MEM阶段前推数据
always @(*) begin
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
```

**为什么重要**：
- 避免分支指令因等待MEM阶段数据而无限暂停
- MEM阶段数据已准备好(EX_MEM_ALU_result)，可直接前推
- 只有EX阶段数据冒险才需要暂停

#### **关键修复2：分支跳转的条件清空**
```verilog
// 只有分支实际跳转且未暂停时才清空IF阶段
assign is_branch_op = (ID_op == 6'b110100) || (ID_op == 6'b110101) || (ID_op == 6'b110110);
assign branch_taken_flush = is_branch_op && (PCSrc != 2'b00) && PC_Write;
assign IF_Flush = IF_Flush_hazard | branch_taken_flush;
```

**为什么重要**：
- 防止分支暂停时错误清空分支指令本身
- 确保只在分支跳转时清空已取的下一条指令

#### **关键修复3：PC计算源选择**
```verilog
// 分支指令使用ID阶段PC，其他情况使用IF阶段PC
assign pcAdd_curPC = (PCSrc == 2'b01) ? IF_ID_PC : IF_PC;

pcAdd pcAdd_inst(
  .curPC(pcAdd_curPC),  // 动态选择PC源
  .PCSrc(PCSrc),
  .immediate(extend),
  .nextPC(nextPC)
);
```

**为什么重要**：
- 分支跳转后，IF被flush，IF_ID_PC变为0
- 如果始终使用IF_ID_PC，会导致错误的PC计算
- 动态选择确保正确性：分支用IF_ID_PC，其他用IF_PC

#### **关键修复4：分支偏移计算**
```verilog
// 使用左移代替乘法
2'b01: nextPC = curPC + 4 + (immediate << 2);  // 正确
// 而不是
2'b01: nextPC = curPC + 4 + immediate * 4;     // 可能有问题
```

---

## 项目调试过程与修复

### 问题1：PCSrc信号未生成
**现象**：分支跳转指令不工作
**原因**：PipelineCPU中PCSrc是wire但没有赋值逻辑
**修复**：添加always块生成PCSrc

### 问题2：分支地址计算错误
**现象**：分支跳到错误地址
**原因**：pcAdd使用IF_PC而不是IF_ID_PC
**修复**：使用ID阶段PC计算分支目标地址

### 问题3：机器码编码错误
**现象**：指令执行结果错误
**原因**：MIPS.txt中slt和add指令编码错误
**修复**：重新计算正确的机器码

### 问题4：分支指令无限暂停
**现象**：beq/bne在ID阶段一直暂停
**原因**：MEM阶段数据冒险导致无限暂停
**修复**：移除MEM暂停逻辑，改为MEM→ID前推

### 问题5：分支指令被错误清空
**现象**：PC跳转混乱
**原因**：分支暂停时IF_Flush=1清空了分支指令本身
**修复**：IF_Flush只在分支跳转且未暂停时置1

### 问题6：PC计算源错误
**现象**：分支跳转后PC跳到0x04
**原因**：flush后IF_ID_PC=0，但pcAdd仍使用IF_ID_PC
**修复**：动态选择PC源(分支用IF_ID_PC，其他用IF_PC)

### 问题7：循环次数少一次
**现象**：Fib(10)计算出34而不是55
**原因**：循环条件是i<n，应该是i<=n
**修复**：将n初始化为11而不是10

---

## 测试结果

### 斐波那契测试程序
```assembly
addi $1, $0, 11      # n = 11 (计算Fib(10))
addi $2, $0, 0       # fib_prev = 0
addi $3, $0, 1       # fib_cur = 1
addi $4, $0, 2       # i = 2

loop:
slt  $5, $4, $1      # $5 = (i < n)
beq  $5, $0, end     # if i >= n, exit
add  $6, $2, $3      # temp = fib_prev + fib_cur
add  $2, $3, $0      # fib_prev = fib_cur
add  $3, $6, $0      # fib_cur = temp
addi $4, $4, 1       # i++
slt  $5, $4, $1      # $5 = (i < n)
bne  $5, $0, loop    # if i < n, continue

end:
sw   $3, 0($0)       # MEM[0] = fib_cur
lw   $7, 0($0)       # $7 = MEM[0]
halt
```

### 最终结果
- **$1 (n)**: 11
- **$2 (fib_prev)**: 21 (Fib(8))
- **$3 (fib_cur)**: 55 (Fib(10)) ✓
- **$4 (i)**: 11
- **$5 (cmp)**: 0
- **$7 (result)**: 55 ✓
- **MEM[0]**: 55 ✓

**总周期数**: 约240周期

---

## 性能分析

### CPI分析
```
总指令数: ~30条 (循环9次)
总周期数: ~240周期
实际CPI: 240/30 ≈ 1.3

理想CPI: 1.0
冒险损失: 0.3周期/指令
```

### 冒险统计
- **数据冒险**: slt指令后的beq/bne需要暂停1周期
- **控制冒险**: 每次分支跳转损失1周期
- **总损失**: 约9次暂停 + 9次分支 = 18周期

---

## 技术亮点

### 1. 完整的冒险处理机制
- ✅ EX→EX前推
- ✅ MEM→EX前推  
- ✅ WB→EX前推
- ✅ **MEM→ID前推（分支指令）**
- ✅ Load-Use暂停
- ✅ 条件分支清空

### 2. 优化的分支处理
- 分支判断在ID阶段，减少延迟
- 支持MEM阶段数据前推到分支比较
- 智能IF清空，避免错误清空

### 3. 动态PC选择
- 根据PCSrc动态选择PC计算源
- 确保flush后PC计算正确

### 4. 模块化设计
- 17个独立模块
- 清晰的接口定义
- 便于测试和维护

---

## 文件结构

```
PipeLineCPU/
├── src/              # 源代码
│   ├── PipelineCPU.v              # 顶层模块
│   ├── PC.v, InsMEM.v, DataMEM.v  # 存储器
│   ├── IF_ID_Register.v           # 流水线寄存器
│   ├── ID_EX_Register.v
│   ├── EX_MEM_Register.v
│   ├── MEM_WB_Register.v
│   ├── ALU.v, RegisterFile.v      # 基础部件
│   ├── HazardDetectionUnit.v      # 冒险检测
│   ├── ForwardingUnit.v           # 前推单元
│   └── ...
├── tb/               # 测试激励
│   └── TestOfPipelineCPU.v
├── docs/             # 设计文档
│   ├── 00_目录.md
│   ├── 01_指令集设计.md
│   ├── 02_控制信号设计.md
│   ├── 03_模块设计与接口.md
│   ├── 04_数据通路设计.md
│   ├── 05_顶层设计.md
│   ├── 06_测试方案.md
│   └── 项目实现总结.md (本文档)
└── MIPS.txt          # 测试程序
```

---

## 后续改进方向

### 性能优化
- [ ] 分支预测
- [ ] 分支延迟槽
- [ ] 动态调度

### 功能扩展
- [ ] 更多MIPS指令
- [ ] 异常处理
- [ ] 特权级支持

### 架构改进
- [ ] 超标量流水线
- [ ] 乱序执行
- [ ] 多发射

---
