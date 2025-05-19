function [model, vars] = build_model(mpc, conf)
% BUILD_MODEL 使用YALMIP构建基于分支流模型的二阶锥优化模型
% 输入：
%   mpc - 包含网络数据的结构体（所有数据均为标幺值）
% 输出：
%   model - YALMIP优化模型
%   vars - YALMIP决策变量

%% 获取系统规模
bus_num = size(mpc.bus, 1);    % 母线数量
bra_num = size(mpc.branch, 1); % 支路数量
gen_num = size(mpc.gen, 1);    % 发电机数量
pv_num = size(mpc.pv, 1);      % 光伏数量
wind_num = size(mpc.wind, 1);  % 风电数量
ess_num = size(mpc.ess, 1);    % 储能数量
time_period_num = conf.time;   % 时段数量
t = 24 / time_period_num;      % 每个时段时长
S_base = mpc.S_base;           % 容量基准值

%% 定义决策变量
vars.v = sdpvar(bus_num, time_period_num, conf.scenarios);         % 电压幅值平方变量
vars.l = sdpvar(bra_num, time_period_num, conf.scenarios);         % 支路电流平方变量
vars.P = sdpvar(bra_num, time_period_num, conf.scenarios);         % 支路有功变量
vars.Q = sdpvar(bra_num, time_period_num, conf.scenarios);         % 支路无功变量
vars.P_trans = sdpvar(conf.scenarios, time_period_num);            % 上级变压器传输有功
vars.Q_trans = sdpvar(conf.scenarios, time_period_num);            % 上级变压器传输无功
vars.P_gen = sdpvar(gen_num, time_period_num, conf.scenarios);     % 发电机有功出力
vars.Q_gen = sdpvar(gen_num, time_period_num, conf.scenarios);     % 发电机无功出力
vars.P_pv = sdpvar(pv_num, time_period_num, conf.scenarios);       % 光伏有功出力
vars.S_pv = sdpvar(pv_num, 1);                                     % 光伏配置容量
vars.P_wind = sdpvar(wind_num, time_period_num, conf.scenarios);   % 风电有功出力
vars.S_wind = sdpvar(wind_num, 1);                                 % 风电配置容量
vars.P_ess_in = sdpvar(ess_num, time_period_num, conf.scenarios);  % 储能有功输入
vars.P_ess_out = sdpvar(ess_num, time_period_num, conf.scenarios); % 储能有功输出
vars.E_ess = sdpvar(ess_num, 1);                                   % 储能配置容量
vars.state_in = binvar(ess_num, time_period_num, conf.scenarios);  % 储能充电状态
vars.state_out = binvar(ess_num, time_period_num, conf.scenarios); % 储能放电状态
vars.soc = sdpvar(ess_num, time_period_num + 1, conf.scenarios);   % 储能电量

vars.tactical_wind = binvar(wind_num, 1); % 风电作业层决策
vars.tactical_pv = binvar(pv_num, 1);     % 光伏作业层决策
vars.tactical_ess = binvar(ess_num, 1);   % 储能作业层决策

% gen_inv_cost = sdpvar(ng, 1);  % 发电机投资成本
pv_inv_cost = sdpvar(1);   % 光伏投资成本
wind_inv_cost = sdpvar(1); % 风电投资成本
ess_inv_cost = sdpvar(1);  % 储能投资成本
% gen_run_cost = sdpvar(conf.scenarios); % 发电机运行成本
pv_run_cost = sdpvar(conf.scenarios);    % 光伏运行成本
wind_run_cost = sdpvar(conf.scenarios);  % 风电运行成本
ess_run_cost = sdpvar(conf.scenarios);   % 储能运行成本
purchase_cost = sdpvar(conf.scenarios);  % 购电成本
branch_cost = sdpvar(conf.scenarios);    % 支路功率损耗成本

%% 构建关联矩阵
mat_trans_bus = sparse(1, 1, 1, bus_num, 1);
mat_from_bus = sparse(mpc.branch(:, 1), 1:bra_num, ones(bra_num, 1), bus_num, bra_num);
mat_to_bus = sparse(mpc.branch(:, 2), 1:bra_num, ones(bra_num, 1), bus_num, bra_num);
mat_gen_bus = sparse(mpc.gen(:, 1), 1:gen_num, ones(gen_num, 1), bus_num, gen_num);
mat_pv_bus = sparse(mpc.pv(:, 1), 1:pv_num, ones(pv_num, 1), bus_num, pv_num);
mat_wind_bus = sparse(mpc.wind(:, 1), 1:wind_num, ones(wind_num, 1), bus_num, wind_num);
mat_ess_bus = sparse(mpc.ess(:, 1), 1:ess_num, ones(ess_num, 1), bus_num, ess_num);

r = mpc.branch(:, 3);
x = mpc.branch(:, 4);
pf_pv = mpc.pv(:, 4);
pf_wind = mpc.wind(:, 4);
pf_ess = mpc.ess(:, 4);

C = [];

%% 构建目标函数
vars.inv_cost = S_base * 1000 / 365 * (pv_inv_cost + wind_inv_cost + ess_inv_cost);
vars.run_cost = sum(pv_run_cost + wind_run_cost + ess_run_cost + purchase_cost + branch_cost);
model.objective = vars.run_cost + vars.inv_cost; % 欠考虑


%% 构建约束条件
% 投资成本
C = [C;
    % gen_inv_cost = sum(mpc.gen(:, 7) ./ ((1 - mpc.gen(:, 8)) .* mpc.gen(:, 9) .* mpc.gen(:, 10)));  % 发电机投资成本
    pv_inv_cost == sum(mpc.pv(:, 6) .* mpc.pv(:, 7) .* vars.S_pv);  % 光伏投资单位容量时间成本
    wind_inv_cost == sum(mpc.wind(:, 6) .* mpc.wind(:, 7) .* vars.S_wind);  % 风电投资单位容量时间成本
    ess_inv_cost == sum(mpc.ess(:, 6) .* vars.E_ess);  % 储能投资单位容量时间成本
];

% 容量配置约束
C = [C;
    vars.S_pv <= mpc.pv(:, 5) .* vars.tactical_pv;  % 光伏配置容量
    vars.S_wind <= mpc.wind(:, 5) .* vars.tactical_wind;  % 风电配置容量
    10 * vars.tactical_ess <= S_base * vars.E_ess <= mpc.ess(:, 5) .* vars.tactical_ess;  % 电量限制
    % sum(vars.tactical_wind) <= 2; % 风电最大安装数量
];

% 变压器传输约束
C = [C;
    -1000 <= vars.P_trans <= 1000;
    -1000 <= vars.Q_trans <= 1000;
];

% 未安装设备时的特判(为了避免重复定义无用约束)
if ~mpc.flag.gen
    C = [C;
        vars.P_gen == 0;
        vars.Q_gen == 0;  
    ];
end

if ~mpc.flag.pv
    C = [C;
        vars.P_pv == 0;  
        vars.S_pv == 0; 
    ];
end

if ~mpc.flag.wind
    C = [C;
        vars.P_wind == 0;
        vars.S_wind == 0;
    ];
end

if ~mpc.flag.ess
    C = [C;
        vars.P_ess_in == 0;   
        vars.P_ess_out == 0;  
        vars.soc == 0;        
        vars.state_in == 0;   
        vars.state_out == 0;  
        vars.E_ess == 0;
    ];
end

for s = 1:conf.scenarios

    C = [C;

    % 运行成本
        % gen_run_cost == Sb * sum((3.6 * mpc.gen(:, 11) ./ (mpc.gen(:, 12) .* (1 - mpc.gen(:, 11)))) .* vars.Pg, "all");  % 常规发电成本
        % 发电机主要是预留接口，燃气轮机组不一定会用上
        pv_run_cost(s) == S_base * 1000 * t * sum(mpc.pv(:, 8) .* vars.P_pv(:, :, s), 'all');  % 光伏发电成本
        wind_run_cost(s) == S_base * 1000 * t * sum(mpc.wind(:, 8) .* vars.P_wind(:, :, s), 'all');  % 风电发电成本
        ess_run_cost(s) == S_base * sum(mpc.ess(:, 7) .* (abs(vars.P_ess_in(:, :, s)) + abs(vars.P_ess_out(:, :, s))) * 1000 * t + mpc.ess(:, 8), 'all');  % 储能电站运行成本
        purchase_cost(s) == S_base * 1000 * t * vars.P_trans(s, :) * mpc.price;  % 购电成本
        branch_cost(s) == S_base * 1000 * t * sum(vars.l(:, :, s) .* r) * mpc.price;  % 支路功率损耗成本（与电价相关）

    % 1. 母线电压约束
        mpc.bus(:, 6).^2 <= vars.v(:, :, s) <= mpc.bus(:, 5).^2;

    % 2. 节点功率平衡约束
        mat_from_bus * vars.P(:, :, s) - mat_to_bus * (vars.P(:, :, s) - r .* vars.l(:, :, s)) == ...
            mat_trans_bus * vars.P_trans(s, :) + ...
            mat_gen_bus * vars.P_gen(:, :, s) + ...
            mat_pv_bus * vars.P_pv(:, :, s) + ...
            mat_wind_bus * vars.P_wind(:, :, s) + ...
            mat_ess_bus * (vars.P_ess_out(:, :, s) - vars.P_ess_in(:, :, s)) - ...
            mpc.pd_time(:, :, s);
        mat_from_bus * vars.Q(:, :, s) - mat_to_bus * (vars.Q(:, :, s) - x .* vars.l(:, :, s)) == ...
            mat_trans_bus * vars.Q_trans(s, :) + ...
            mat_gen_bus * vars.Q_gen(:, :, s) + ...
            mat_pv_bus * (tan(acos(pf_pv)) .* vars.P_pv(:, :, s)) + ...
            mat_wind_bus * (tan(acos(pf_wind)) .* vars.P_wind(:, :, s)) + ...
            mat_ess_bus * (tan(acos(pf_ess)) .* (vars.P_ess_out(:, :, s) - vars.P_ess_in(:, :, s))) - ...
            mpc.qd_time(:, :, s);

    % 3. 支路功率流约束
        vars.P(:, :, s).^2 + vars.Q(:, :, s).^2 <= vars.l(:, :, s) .* (mat_from_bus' * vars.v(:, :, s));
        mat_to_bus' * vars.v(:, :, s) == mat_from_bus' * vars.v(:, :, s) - 2 * (r .* vars.P(:, :, s) + x .* vars.Q(:, :, s)) + (r.^2 + x.^2) .* vars.l(:, :, s);
        0 <= vars.l(:, :, s) <= mpc.branch(:, 7).^2;
    ];

    % 4. 发电机出力约束
    if mpc.flag.gen
        C = [C;
            mpc.gen(:, 3) <= vars.P_gen(:, :, s) <= mpc.gen(:, 2);   % 有功出力限制
            mpc.gen(:, 5) <= vars.Q_gen(:, :, s) <= mpc.gen(:, 4);   % 无功出力限制
            vars.P_gen(:, :, s).^2 + vars.Q_gen(:, :, s).^2 <= mpc.gen(:, 6).^2;  % 容量限制
        ];
    end

    % 5. 光伏出力约束
    if mpc.flag.pv
        C = [C;
            mpc.pv(:, 3) <= vars.P_pv(:, :, s) <= mpc.pv(:, 2);  % 有功出力限制
            vars.P_pv(:, :, s) <= pf_pv .* (vars.S_pv * mpc.pv_time(s, :));
        ];
    end

    % 6. 风电出力约束
    if mpc.flag.wind
        C = [C;
            mpc.wind(:, 3) <= vars.P_wind(:, :, s) <= mpc.wind(:, 2);  % 有功出力限制
            vars.P_wind(:, :, s) <= pf_wind .* (vars.S_wind * mpc.wind_time(s, :));
        ];
    end

    % 7. 储能出力约束
    if mpc.flag.ess
        C = [C;
            0 <= vars.P_ess_in(:, :, s) <= mpc.ess(:, 2) .* vars.tactical_ess;   % 有功出力限制
            0 <= vars.P_ess_out(:, :, s) <= mpc.ess(:, 3) .* vars.tactical_ess;  % 有功出力限制
            vars.state_in(:, :, s) + vars.state_out(:, :, s) <= 1;     % 选择充放电状态 
            0 <= vars.P_ess_in(:, :, s) <= 0.2 * mpc.ess(:, 5) .* vars.state_in(:, :, s);    % 充电功率限制
            0 <= vars.P_ess_out(:, :, s) <= 0.2 * mpc.ess(:, 5) .* vars.state_out(:, :, s);  % 放电功率限制
            0.2 * vars.E_ess <= vars.soc(:, :, s) <= 0.8 * vars.E_ess;  % 储能电量限制
            vars.soc(:, 1, s) == 0.5 * vars.E_ess;  % 初始电量
            vars.soc(:, 2:end, s) == vars.soc(:, 1:end-1, s) + 0.9 * vars.P_ess_in(:, :, s) - 1.11 * vars.P_ess_out(:, :, s);  % 储能电量约束
        ];
    end

end

model.constraints = C;

end
