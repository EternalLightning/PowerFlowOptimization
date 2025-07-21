# 潮流计算优化程序

[项目地址](https://github.com/EternalLightning/PowerFlowOptimization) 
本项目是一个潮流优化计算程序，旨在打造一个相对通用的、开箱即用的程序，兼容新能源处理，方便科研计算。

## 数据格式定义

在案例文件中，需要定义一个结构体 `case_mpc`，包含以下矩阵和数据格式。所有参数均使用标幺制。

### 母线数据格式 (`case_mpc.bus`)
所有参数使用标幺制。

| 列号 | 数据类型 | 变量名 | 描述                   |
|------|----------|--------|------------------------|
| 1    | 整数     | `bus_num` | 母线编号               |
| 2    | 整数     | `type`   | 母线类型 (1=PQ, 2=PV, 3=平衡节点) |
| 3    | 实数     | `V_mag`     | 电压幅值 (p.u.)        |
| 4    | 实数     | `V_angle`  | 电压相角 (度)          |
| 5    | 实数     | `V_max`   | 最小电压限值 (p.u.)    |
| 6    | 实数     | `V_min`   | 最大电压限值 (p.u.)    |

对于第一列，我们希望 `bus_num` 值与行号严格对应。
对于不同的母线类型，程序只会选取所需的数据，因此您可以把无用数据置零（如 PQ 节点只选取 5、6 列）。

### 支路数据格式 (`case_mpc.branch`)
所有参数使用标幺制。

| 列号 | 数据类型 | 变量名 | 描述                   |
|------|----------|--------|------------------------|
| 1    | 整数     | `from_bus` | 起始母线编号           |
| 2    | 整数     | `to_bus`  | 终止母线编号           |
| 3    | 实数     | `r`      | 支路电阻 (p.u.)      |
| 4    | 实数     | `x`      | 支路电抗 (p.u.)      |
| 5    | 实数     | `b`      | 支路导纳 (p.u.)  |
| 6    | 实数     | `I_max`  | 最大电流限值 (p.u.) |

### 发电机数据格式 (`case_mpc.gen`)
所有参数使用标幺制。

| 列号 | 数据类型 | 变量名 | 描述                   |
|------|----------|--------|------------------------|
| 1    | 整数     | `conn_bus` | 相连母线编号               |
| 2    | 实数     | `P_max`   | 最大有功出力 Pmax (p.u.) |
| 3    | 实数     | `P_min`   | 最小有功出力 Pmin (p.u.) |
| 4    | 实数     | `Q_max`   | 最大无功出力 Qmax (p.u.) |
| 5    | 实数     | `Q_min`   | 最小无功出力 Qmin (p.u.) |
| 6    | 实数     | `S`      | 额定容量 (p.u.)        |
| 7    | 实数     | `SIC` | 相对于电站净功率折算的动态比投资费用       |
| 8    | 实数     | `loss`   | 发电机终端到售电结算点之间的线损率 |
| 9    | 实数     | `a`      | 电站的经济使用寿命  |
| 10   | 实数     | `tu`     | 发电设备的年运行利用小时数         |
| 11   | 实数     | `CF`     | 燃料费用     |
| 12   | 实数     | `eff`     | 发电效率     |

### 光伏发电数据格式 (`case_mpc.pv`)
所有参数使用标幺制。

| 列号 | 数据类型 | 变量名 | 描述                   |
|------|----------|--------|------------------------|
| 1    | 整数     | `conn_bus` | 相连母线编号               |
| 2    | 实数     | `pf_s`   | 功率因数（默认滞后）         |
| 3    | 实数     | `S`      | 最大可配置容量               |
| 4    | 实数     | `k` | 折算到每日的成本系数   |
| 5    | 实数     | `a` | 单位容量投资成本       |
| 6    | 实数     | `b` | 每度电的发电成本       |
| 7    | 实数     | `eff` | 光伏转换效率 |

光伏投资成本
$$C_\mathrm{pv}^\mathrm{inv}=\frac{k \cdot aS×10^3}{365}$$
光伏运行成本
$$C_\mathrm{pv}^\mathrm{run}=bP_\mathrm{pv}\cdot t×10^3$$

### 风电数据格式 (`case_mpc.wind`)
所有参数使用标幺制。

| 列号 | 数据类型 | 变量名 | 描述                   |
|------|----------|--------|------------------------|
| 1    | 整数     | `conn_bus` | 相连母线编号  |
| 2    | 实数     | `pf_w`   | 功率因数 （默认滞后）  |
| 3    | 实数     | `S`    | 最大可配置容量               |
| 4    | 实数     | `k` | 折算到每日的成本系数   |
| 5    | 实数     | `a` | 单位容量投资成本       |
| 6    | 实数     | `b` | 每度电的发电成本       |
| 7    | 实数     | `R` | 叶片半径       |
| 8    | 实数     | `C` | 风能利用系数       |

风电投资成本
$$C_\mathrm{wind}^\mathrm{inv}=\frac{k \cdot aS×10^3}{365}$$
风电运行成本
$$C_\mathrm{wind}^\mathrm{run}=bP_\mathrm{wind}\cdot t×10^3$$

### 储能矩阵格式 (`case_mpc.storage`)
所有参数使用标幺制。

| 列号 | 数据类型 | 变量名 | 描述                   |
|------|----------|--------|------------------------|
| 1    | 整数     | `conn_bus` | 相连母线编号               |
| 2    | 实数     | `Pmax_out` | 最大输出有功出力 (p.u.) |
| 3    | 实数     | `Pmax_in` | 最大输入有功出力 (P_min < 0) (p.u.) |
| 4    | 实数     | `pf_st`     | 功率因数（默认滞后）     |
| 5    | 实数     | `E` | 最大可配置容量 (MWh)     |
| 6    | 实数     | `a` | 单位容量投资成本       |
| 7    | 实数     | `b` | 每千瓦时成本系数       |
| 8    | 实数     | `c` | 运维成本               |

储能投资成本
$$C_\mathrm{ess}^\mathrm{inv}=aE\times10^3$$
储能运行成本
$$C_\mathrm{ess}^\mathrm{run}=bP_\mathrm{ess}\cdot t×10^3+c$$

### 有功负荷矩阵 (`case_mpc.pd_time`)
一个 `bus_num * conf.time * s` 的三维矩阵，为每个母线每个时段的有功负荷需求。其中 `s` 为场景数。

### 无功负荷矩阵 (`case_mpc.qd_time`)
一个 `bus_num * conf.time * s` 的矩阵，为每个母线每个时段的无功负荷需求。其中 `s` 为场景数。

### 电价矩阵 (`case_mpc.price`)
每度电的价格，一个长度为 `conf.time` 的列向量，记录每个时段的电价。

### 光伏出力矩阵 (`case_mpc.pv_time`)
一个 `s * conf.time` 的矩阵，为每个光伏设备每个时段的出力。

### 风电出力矩阵 (`case_mpc.wind_time`)
一个 `s * conf.time` 的矩阵，为每个风电设备每个时段的出力。

### 场景概率矩阵 (`case_mpc.prob`)
一个长度为 `s` 的行向量，记录每个场景的概率。

## 模型目标与约束条件

### 目标函数
$$ \min\left\{ \sum_{t=1}^{T} \sum_{s=1}^{S} p_s\left( C_\mathrm{pv}^\mathrm{run}(t, s) + C_\mathrm{wind}^\mathrm{run}(t, s) + C_\mathrm{ess}^\mathrm{run}(t, s) \right) + C_\mathrm{pv}^\mathrm{inv} + C_\mathrm{wind}^\mathrm{inv} + C_\mathrm{ess}^\mathrm{inv} + C_\mathrm{pur}^\mathrm{inv} + C_\mathrm{loss}^\mathrm{inv}\right\} $$

式中，
$T$ 为时段数、$S$ 为场景数、$p_s$ 为场景 $s$ 出现的概率；
$C^\mathrm{inv}$ 为投资成本、$C^\mathrm{run}$ 为运行成本；
下标 $\mathrm{pv}$、$\mathrm{wind}$、$\mathrm{ess}$ 分别表示光伏、风电、储能设备；
$C_\mathrm{pur}^\mathrm{inv}$、$C_\mathrm{loss}^\mathrm{inv}$ 表示购电成本和支路损耗成本。

各类成本的计算方式已在数据格式定义中说明。

### 约束条件

#### 容量配置约束

$$ 
\begin{cases}
0 \leq \mathbf{S}_\mathrm{pv} \leq \mathbf{S}_\mathrm{pv}^\mathrm{max} \cdot \mathbf{T}_\mathrm{pv}  \\
0 \leq \mathbf{S}_\mathrm{wind} \leq \mathbf{S}_\mathrm{wind}^\mathrm{max} \cdot \mathbf{T}_\mathrm{wind}  \\
2 \mathbf{T}_\mathrm{ess}\leq E_\mathrm{ess} \leq E_\mathrm{ess}^\mathrm{max}\cdot \mathbf{T}_\mathrm{ess}
\end{cases}
$$

式中，
矩阵 $\mathbf{S}_\mathrm{pv}$、$\mathbf{S}_\mathrm{wind}$、$\mathbf{E}_\mathrm{ess}$ 分别表示光伏、风电、储能设备的配置容量；
$\mathbf{S}_\mathrm{pv}^\mathrm{max}$、$\mathbf{S}_\mathrm{wind}^\mathrm{max}$、$\mathbf{E}_\mathrm{ess}^\mathrm{max}$ 分别表示光伏、风电、储能设备的最大配置容量；
$\mathbf{T}_\mathrm{pv}$、$\mathbf{T}_\mathrm{wind}$、$\mathbf{T}_\mathrm{ess}$ 分别表示光伏、风电、储能设备的决策矩阵，里面的元素只取 0 或 1，表示是否安装这台设备。

#### 1 号节点变压器传输约束

$$
\begin{cases}
-P_\mathrm{trans}^\mathrm{max} \leq P_\mathrm{trans} \leq P_\mathrm{trans}^\mathrm{max} \\
P_\mathrm{trans}^2+Q_\mathrm{trans}^2 \leq S_\mathrm{trans,N}^\mathrm{2}
\end{cases}
$$

#### 母线电压约束

$$ \mathbf{U}_\mathrm{min} \leq \mathbf{U}(t, s) \leq \mathbf{U}_\mathrm{max} \quad (1\leq t\leq T,\  1\leq s \leq S) $$

式中，
$\mathbf{U}_\mathrm{min}$、$\mathbf{U}_\mathrm{max}$ 均为列向量，分别为母线电压的最小和最大限值；
$\mathbf{U}(t, s)$ 为一个列向量，表示时段 $t$、场景 $s$ 下的母线电压。

#### 节点功率平衡约束

对于任意场景任意时段的每一个节点
$$ 
\begin{cases}
\displaystyle\sum_{j=1}^{m} P_j = P_\mathrm{pv} + P_\mathrm{wind} + P_\mathrm{ess} + P_\mathrm{trans} - P_\mathrm{load} + \sum_{i=1}^{n} P_i - r_il_i\\
\\
\displaystyle\sum_{j=1}^{m} Q_j = Q_\mathrm{pv} + Q_\mathrm{wind} + Q_\mathrm{ess} + Q_\mathrm{trans} - Q_\mathrm{load} + \sum_{i=1}^{n} Q_i - x_il_i
\end{cases}
$$

式中，
$P_i$ 为与本节点从**相邻上级节点** $i$ 接受的有功功率，$P_j$ 为与本节点向**相邻下级节点** $j$ 发送的有功功率；
$l_i$ 为支路 $i$ 的电流幅值平方；
$P_\mathrm{pv}$、$P_\mathrm{wind}$、$P_\mathrm{ess}$ 分别为光伏、风电、储能设备在该节点的出力；
$P_\mathrm{load}$ 为该节点的有功负荷需求；
对于无功功率，意义同上。

#### 支路功率流约束

对于任意场景任意时段的支路 $(i, j)$，有
$$ 
\begin{cases}
P_{ij}^2 + Q_{ij}^2 \leq v_i^2l_{ij}^2 \\
v_j^2 = v_i^2 - 2r_iP_{ij} - 2x_iQ_{ij} + (r_i^2 + x_i^2)l_{ij}
\end{cases}
$$

式中，
$P_{ij}$、$Q_{ij}$ 分别为支路 $(i, j)$ 的有功和无功功率流；
$v_i$、$v_j$ 分别为母线 $i$、$j$ 的电压幅值；
$l_{ij}$ 为支路 $(i, j)$ 的电流幅值平方；

#### 光伏和风电出力约束

对于任意场景任意时段的光伏和风电设备，均有
$$ 
\begin{cases}
0 \leq P_\mathrm{pv}(t, s) \leq \eta_\mathrm{pv} S_\mathrm{pv} \cdot I_\mathrm{pv} \\
0 \leq P_\mathrm{wind}(t, s) \leq \eta_\mathrm{wind}S_\mathrm{wind} \cdot I_\mathrm{wind}
\end{cases}
\quad
(1\leq t\leq T,\  1\leq s \leq S)
$$

式中，
$P_\mathrm{pv}(t, s)$、$P_\mathrm{wind}(t, s)$ 分别为时段 $t$、场景 $s$ 下的光伏和风电出力；
$\eta_\mathrm{pv}$、$\eta_\mathrm{wind}$ 分别为光伏和风电的转换效率；
$S_\mathrm{pv}$、$S_\mathrm{wind}$ 分别为光伏和风电设备的配置容量；
$I_\mathrm{pv}$、$I_\mathrm{wind}$ 分别为此刻的辐照度系数和风力系数，数值均已转化为出力。

#### 储能设备充放电约束

对于任意场景任意时段的储能设备，均有
$$ 
\begin{cases}
0\leq P_\mathrm{in}(t, s) \leq E_\mathrm{ess} \cdot T_\mathrm{ess} \\
0\leq P_\mathrm{out}(t, s) \leq E_\mathrm{ess} \cdot T_\mathrm{ess} \\
f_\mathrm{in}+f_\mathrm{out}=1\\
soc_{i+1}-soc_i = 0.9P_\mathrm{in}(t, s) - 1.11 P_\mathrm{out}(t, s)
\end{cases}
$$

式中，
$P_\mathrm{in}(t, s)$、$P_\mathrm{out}(t, s)$ 分别为时段 $t$、场景 $s$ 下的储能设备充电和放电功率；
$E_\mathrm{ess}$ 为储能设备的配置容量；
$T_\mathrm{ess}$ 为储能设备的决策矩阵，里面的元素只取 0 或 1，表示是否安装这台设备；
$f_\mathrm{in}$、$f_\mathrm{out}$ 分别为充电和放电的决策变量，取值为 0 或 1；
$soc_i$ 为储能设备在时段 $i$ 的荷电状态（SOC）。

## 使用说明
使用本程序，您需要在 `config.m` 中指定案例文件 (`conf.network.case_file`)。其他设置在 `config.m` 中已有明确的注释，请自行设置。
案例文件中，需要定义一个结构体 `case_mpc`，至少包含上述矩阵，否则无法正常工作。