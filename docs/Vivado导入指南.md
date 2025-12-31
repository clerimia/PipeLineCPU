# 如何将项目导入Vivado

## 方法一：使用Vivado GUI创建项目（推荐）

### 步骤1：启动Vivado并创建新项目

1. 打开Vivado 2025.1.7（或其他版本）
2. 点击 **Create Project**
3. 点击 **Next**

### 步骤2：项目设置

1. **Project name**: `PipelineCPU`
2. **Project location**: 选择项目根目录的父文件夹
   ```
   D:\MyScience_Demo\大学课程\大三上\系统硬件设计\
   ```
3. 勾选 **Create project subdirectory**
4. 点击 **Next**

### 步骤3：项目类型

1. 选择 **RTL Project**
2. **不要**勾选 "Do not specify sources at this time"
3. 点击 **Next**

### 步骤4：添加源文件

点击 **Add Files**，导航到 `src` 目录，添加以下文件：

**必需的源文件（按添加顺序）：**
```
src/PipelineCPU.v              (顶层模块)
src/PC.v
src/InsMEM.v
src/IF_ID_Register.v
src/InstructionCut.v
src/PipelineControlUnit.v
src/RegisterFile.v
src/SignZeroExtend.v
src/ID_EX_Register.v
src/WriteRegSelector.v
src/ForwardingUnit.v
src/ALU.v
src/EX_MEM_Register.v
src/DataMEM.v
src/MEM_WB_Register.v
src/HazardDetectionUnit.v
src/pcAdd.v
```

**注意事项：**
- 确保所有文件都被添加
- **Copy sources into project** 可以不勾选（保持文件在原位置）
- 点击 **Next**

### 步骤5：添加约束文件（可选）

- 如果有XDC约束文件，在此添加
- 否则点击 **Next** 跳过

### 步骤6：添加仿真文件

点击 **Add Files**，导航到 `tb` 目录，添加：
```
tb/TestOfPipelineCPU.v
```

**注意：**
- 在添加时，**File type** 选择为 **Simulation Sources**
- 点击 **Next**

### 步骤7：选择开发板或芯片

1. **Default Part** 选择你的FPGA芯片型号
   - 例如：`xc7a35tcpg236-1` (Artix-7)
   - 或根据你的开发板选择
2. 点击 **Next**

### 步骤8：完成创建

1. 检查项目摘要
2. 点击 **Finish**

---

## 方法二：使用TCL脚本创建项目

### 创建项目脚本

创建文件 `create_project.tcl`（内容如下）：

```tcl
# 设置项目名称和位置
set project_name "PipelineCPU"
set project_dir "D:/MyScience_Demo/大学课程/大三上/系统硬件设计/PipeLineCPU"

# 创建项目
create_project ${project_name} ${project_dir} -force

# 设置目标芯片（根据实际开发板修改）
set_property part xc7a35tcpg236-1 [current_project]

# 添加源文件
add_files -norecurse {
    src/PipelineCPU.v
    src/PC.v
    src/InsMEM.v
    src/IF_ID_Register.v
    src/InstructionCut.v
    src/PipelineControlUnit.v
    src/RegisterFile.v
    src/SignZeroExtend.v
    src/ID_EX_Register.v
    src/WriteRegSelector.v
    src/ForwardingUnit.v
    src/ALU.v
    src/EX_MEM_Register.v
    src/DataMEM.v
    src/MEM_WB_Register.v
    src/HazardDetectionUnit.v
    src/pcAdd.v
}

# 添加仿真文件
add_files -fileset sim_1 -norecurse {
    tb/TestOfPipelineCPU.v
}

# 添加测试数据文件
add_files -norecurse MIPS.txt
set_property file_type {Memory Initialization Files} [get_files MIPS.txt]

# 设置顶层模块
set_property top PipelineCPU [current_fileset]
set_property top TestOfPipelineCPU [get_filesets sim_1]

# 更新编译顺序
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "项目创建完成！"
```

### 运行TCL脚本

1. 打开Vivado
2. 点击 **Tools → Run Tcl Script**
3. 选择 `create_project.tcl`
4. 点击 **OK**

---

## 项目配置检查

创建项目后，请检查以下设置：

### 1. 文件层次检查

在 **Sources** 窗口中查看：
```
Design Sources
  └─ PipelineCPU (PipelineCPU.v)
      ├─ PC
      ├─ InsMEM
      ├─ IF_ID_Register
      ├─ InstructionCut
      ├─ PipelineControlUnit
      ├─ RegisterFile
      ├─ SignZeroExtend
      ├─ ID_EX_Register
      ├─ WriteRegSelector
      ├─ ForwardingUnit
      ├─ ALU
      ├─ EX_MEM_Register
      ├─ DataMEM
      ├─ MEM_WB_Register
      ├─ HazardDetectionUnit
      └─ pcAdd

Simulation Sources
  └─ sim_1
      └─ TestOfPipelineCPU (TestOfPipelineCPU.v)
```

### 2. 添加MIPS.txt文件

**重要：** 指令存储器需要从MIPS.txt读取数据

1. 右键点击 **Design Sources**
2. 选择 **Add Sources**
3. 选择 **Add or create design sources**
4. 添加 `MIPS.txt`
5. 右键 `MIPS.txt` → **Properties**
6. 将 **Type** 设置为 **Memory Initialization Files**

### 3. 仿真设置

1. 点击 **Settings**
2. 选择 **Simulation**
3. **Simulation top module name**: `TestOfPipelineCPU`
4. **Simulation Run Time**: 设置为 `5000ns` 或更长

---

## 运行仿真

### 启动仿真

1. 在左侧 **Flow Navigator** 中
2. 点击 **Run Simulation → Run Behavioral Simulation**
3. 等待编译和仿真启动

### 查看波形

仿真启动后：

1. **添加信号到波形窗口**：
   - 在 **Scope** 窗口选择 `TestOfPipelineCPU`
   - 在 **Objects** 窗口选择要观察的信号
   - 右键 → **Add to Wave Window**

2. **推荐观察的信号**：
   ```
   CLK
   RST
   curPC
   IF_instruction
   ID_instruction
   ID_op
   EX_ALU_result
   MEM_ALU_result
   WB_WriteReg
   WB_WriteData
   WB_RegWre
   ```

3. **运行仿真**：
   - 点击工具栏的 **Run All** 或
   - 在TCL Console输入：`run 5000ns`

4. **查看结果**：
   - 使用缩放工具调整波形
   - 使用标记工具定位关键时刻

---

## 综合与实现（如果需要上板）

### 添加约束文件

创建 `constraints.xdc` 文件：

```tcl
# 时钟约束（根据实际开发板修改）
create_clock -period 40.000 -name CLK -waveform {0.000 20.000} [get_ports CLK]

# 复位引脚（根据实际开发板修改）
# set_property PACKAGE_PIN xxx [get_ports RST]
# set_property IOSTANDARD LVCMOS33 [get_ports RST]

# 时钟引脚（根据实际开发板修改）
# set_property PACKAGE_PIN xxx [get_ports CLK]
# set_property IOSTANDARD LVCMOS33 [get_ports CLK]
```

### 运行综合

1. 点击 **Run Synthesis**
2. 等待综合完成
3. 查看综合报告

### 运行实现

1. 点击 **Run Implementation**
2. 等待实现完成
3. 查看时序报告

### 生成比特流

1. 点击 **Generate Bitstream**
2. 等待生成完成
3. 下载到FPGA开发板

---

## 常见问题解决

### 问题1：找不到MIPS.txt文件

**解决方法**：
1. 确保MIPS.txt在项目根目录
2. 在InsMEM.v中检查文件路径
3. 或修改为绝对路径：
   ```verilog
   $readmemh("D:/MyScience_Demo/大学课程/大三上/系统硬件设计/PipeLineCPU/MIPS.txt", rom);
   ```

### 问题2：编译错误

**解决方法**：
1. 检查所有源文件都已添加
2. 查看错误信息定位问题文件
3. 确保文件编码为UTF-8

### 问题3：仿真无波形

**解决方法**：
1. 检查仿真时间是否足够长
2. 确认复位信号正确
3. 手动添加信号到波形窗口

### 问题4：综合失败

**解决方法**：
1. 查看综合日志
2. 检查是否有语法错误
3. 确认目标器件支持当前设计

---

## 项目文件结构

确保你的项目目录结构如下：

```
PipeLineCPU/
├── src/                    # 源代码目录
│   ├── PipelineCPU.v      # 顶层模块
│   ├── PC.v
│   ├── InsMEM.v
│   ├── IF_ID_Register.v
│   ├── InstructionCut.v
│   ├── PipelineControlUnit.v
│   ├── RegisterFile.v
│   ├── SignZeroExtend.v
│   ├── ID_EX_Register.v
│   ├── WriteRegSelector.v
│   ├── ForwardingUnit.v
│   ├── ALU.v
│   ├── EX_MEM_Register.v
│   ├── DataMEM.v
│   ├── MEM_WB_Register.v
│   ├── HazardDetectionUnit.v
│   └── pcAdd.v
├── tb/                     # 测试文件目录
│   └── TestOfPipelineCPU.v
├── MIPS.txt                # 指令数据文件
├── docs/                   # 文档目录
└── create_project.tcl      # 项目创建脚本（可选）
```

---

## 快速开始命令

如果你熟悉TCL，可以直接在Vivado TCL Console中执行：

```tcl
# 进入项目目录
cd "D:/MyScience_Demo/大学课程/大三上/系统硬件设计/PipeLineCPU"

# 运行项目创建脚本
source create_project.tcl

# 运行仿真
launch_simulation
run 5000ns
```

---

**提示**：
- 首次使用建议采用**方法一（GUI）**，更直观
- 熟悉后可以使用**方法二（TCL脚本）**，更快捷
- 仿真前务必确保MIPS.txt文件路径正确
