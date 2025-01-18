function mpc = data_format(conf)
% DATA_FORMAT 定义配网优化问题的数据格式
% 返回一个包含所有必要字段的结构体

% 定义基值
mpc.baseS = conf.base.S;    % 基准容量
mpc.baseU = conf.base.U;    % 基准电压
mpc.baseZ = mpc.baseU ^ 2 / mpc.baseS;  % 基准阻抗
mpc.baseI = mpc.baseS / (mpc.baseU * sqrt(3)); % 基准电流

% 母线数据格式 (bus matrix) - 所有参数使用标幺制
% 列号  数据类型    描述
% 1     整数      母线编号
% 2     整数      母线类型 (1=PQ, 2=PV, 3=平衡节点)
% 3     实数      电压幅值 (p.u.)
% 4     实数      电压相角 (度)
% 5     实数      最小电压限值 (p.u.)
% 6     实数      最大电压限值 (p.u.)


% 支路数据格式 (branch matrix) - 所有参数使用标幺制
% 列号  数据类型    描述
% 1     整数      起始母线编号
% 2     整数      终止母线编号
% 3     实数      支路电阻 r (p.u.)
% 4     实数      支路电抗 x (p.u.)
% 5     实数      线路充电导纳 B (p.u.)
% 6     实数      额定容量 S (p.u.)
% 7     实数      最大电流限值 Imax (p.u.)


% 发电机数据格式 (gen matrix) - 所有参数使用标幺制
% 列号  数据类型    描述
% 1     整数      母线编号
% 2     实数      最大有功出力 Pmax (p.u.)
% 3     实数      最小有功出力 Pmin (p.u.)
% 4     实数      最大无功出力 Qmax (p.u.)
% 5     实数      最小无功出力 Qmin (p.u.)
% 6     实数      额定容量 (p.u.)
% 7     实数      发电成本系数 a (p.u.^2)
% 8     实数      发电成本系数 b (p.u.)
% 9     实数      发电成本系数 c


% 光伏发电数据格式 (solar matrix) - 所有参数使用标幺制
% 列号  数据类型    描述
% 1     整数      母线编号
% 2     实数      最大有功出力 (p.u.)
% 3     实数      最小有功出力 (p.u.)
% 4     实数      功率因数
% 5     实数      额定容量
% 6     0/1      运行状态
% 7     实数      每日成本系数
% 此处有功随时间变化，待考虑


% 风电数据格式 (wind matrix) - 所有参数使用标幺制
% 列号  数据类型    描述
% 1     整数      母线编号
% 2     实数      最大有功出力 (p.u.)
% 3     实数      最小有功出力 (p.u.)
% 4     实数      功率因数
% 5     实数      额定容量
% 6     0/1      运行状态
% 7     实数      每日成本系数
% 此处有功随时间变化，待考虑


% 储能矩阵格式 (storage matrix) - 所有参数使用标幺制
% 列号  数据类型    描述
% 1     整数      母线编号
% 2     实数      最大输出有功出力 (p.u.)
% 3     实数      最大输入有功出力 (P_min < 0) (p.u.)
% 4     实数      功率因数
% 5     实数      额定容量
% 6     0/1      运行状态
% 7     实数      每日成本系数
% 待考虑


% 标准测试系统拓扑结构
% IEEE 33节点系统拓扑
mpc.built_in.ieee33 = [
    1  2;  2  3;  3  4;  4  5;  5  6;  6  7;  7  8;  8  9;  9  10;
    10 11; 11 12; 12 13; 13 14; 14 15; 15 16; 16 17; 17 18; 2  19;
    19 20; 20 21; 21 22; 3  23; 23 24; 24 25; 6  26; 26 27; 27 28;
    28 29; 29 30; 30 31; 31 32; 32 33
];

% IEEE 123节点系统拓扑
mpc.built_in.ieee123 = [
    1   123;  123   2;  123   3;  123   7;  
    3     4;  3     5;  5     6;  7     8;  
    8    12;  8     9;  8    13;  9    14;  
    13   34;  13   18;  14   11;  14   10;  
    15   16;  15   17;  18   19;  18   21;  
    19   20;  21   22;  21   23;  23   24;  
    23   25;  25   26;  25   28;  26   27;  
    26   31;  27   33;  28   29;  29   30;  
    30   122;  31   32;  34   15;  35   36;  
    35   40;  36   37;  36   38;  38   39;  
    40   41;  40   42;  42   43;  42   44;  
    44   45;  44   47;  45   46;  47   48;  
    47   49;  49   50;  50   51;  51   116; 
    52   53;  53   54;  54   55;  54   57;  
    55   56;  57   58;  57   60;  58   59;  
    60   61;  60   62;  62   63;  63   64;  
    64   65;  65   66;  67   68;  67   72;  
    67   97;  68   69;  69   70;  70   71;  
    72   73;  72   76;  73   74;  74   75;  
    76   77;  76   86;  77   78;  78   79;  
    78   80;  80   81;  81   82;  81   84;  
    82   83;  84   85;  86   87;  87   88;  
    87   89;  89   90;  89   91;  91   92;  
    91   93;  93   94;  93   95;  95   96;  
    97   98;  98   99;  99   100;  100   118; 
    101   102;  101   105;  102   103;  103   104; 
    105   106;  105   108;  106   107;  108   109; 
    108   115;  109   110;  110   111;  110   112; 
    112   113;  113   114;  121   35;  120   52;  
    119   67;  117   101;  18   121;  13   120;  
    60   119;  116   115
];

% 初始化空矩阵
mpc.bus = [];
mpc.branch = [];
mpc.gen = [];
mpc.solar = [];  % 光伏矩阵
mpc.wind = [];   % 风电矩阵
mpc.storage = [];
mpc.solar_time = [];  % 光伏日变化曲线
mpc.pd_time = [];  % 有功日变化曲线
mpc.qd_time = [];  % 无功日变化曲线
mpc.price = [];  % 电价日变化曲线

end 

% 负荷，电价
% 风
% 先固定负荷