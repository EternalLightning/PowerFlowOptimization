function [model, vars] = build_model(mpc, conf)
% BUILD_MODEL 使用YALMIP构建基于分支流模型的二阶锥优化模型
% 输入：
%   mpc - 包含网络数据的结构体（所有数据均为标幺值）
% 输出：
%   model - YALMIP优化模型
%   vars - YALMIP决策变量

%% 获取系统规模
bus_num = size(mpc.bus, 1);       % 母线数量
bra_num = size(mpc.branch, 1);    % 支路数量
gen_num = size(mpc.gen, 1);       % 发电机数量
pv_num = size(mpc.pv, 1);     % 光伏数量
wind_num = size(mpc.wind, 1);      % 风电数量
storage_num = size(mpc.storage, 1);  % 储能数量
time_period_num = conf.time;              % 时段数量
t = 24 / time_period_num;                 % 每个时段的小时数
S_base = mpc.S_base;            % 容量基准值

%% 定义决策变量
vars.v = sdpvar(bus_num, time_period_num);     % 电压幅值平方变量
vars.l = sdpvar(bra_num, time_period_num);     % 支路电流平方变量
vars.P = sdpvar(bra_num, time_period_num);     % 支路有功变量
vars.Q = sdpvar(bra_num, time_period_num);     % 支路无功变量
vars.P_gen = sdpvar(gen_num, time_period_num);    % 发电机有功出力
vars.Q_gen = sdpvar(gen_num, time_period_num);    % 发电机无功出力
vars.P_pv = sdpvar(pv_num, time_period_num);    % 光伏有功出力
vars.S_pv = sdpvar(pv_num, 1);     % 光伏配置容量
vars.P_wind = sdpvar(wind_num, time_period_num);    % 风电有功出力
vars.S_wind = sdpvar(wind_num, 1);     % 风电配置容量
vars.P_storage_input = sdpvar(storage_num, time_period_num);  % 储能有功输入
vars.P_storage_output = sdpvar(storage_num, time_period_num); % 储能有功输出
vars.E_storage = sdpvar(storage_num, 1);    % 储能配置容量
vars.state_in = binvar(storage_num, time_period_num);  % 储能充电状态
vars.state_out = binvar(storage_num, time_period_num); % 储能放电状态
vars.soc = sdpvar(storage_num, time_period_num + 1);   % 储能电量

vars.tactical_wind = binvar(wind_num, 1);        % 风电作业层决策
vars.tactical_pv = binvar(pv_num, 1);            % 光伏作业层决策
vars.tactical_storage = binvar(storage_num, 1);  % 储能作业层决策

% gen_inv_cost = sdpvar(ng, 1);  % 发电机投资成本
pv_inv_cost = sdpvar(1);  % 光伏投资成本
wind_inv_cost = sdpvar(1);  % 风电投资成本
storage_inv_cost = sdpvar(1);  % 储能投资成本
gen_run_cost = sdpvar(1);  % 发电机运行成本
pv_run_cost = sdpvar(1);  % 光伏运行成本
wind_run_cost = sdpvar(1);  % 风电运行成本
storage_run_cost = sdpvar(1);  % 储能运行成本
purchase_cost = sdpvar(1);  % 购电成本
branch_cost = sdpvar(1);  % 支路功率损耗成本

%% 构建关联矩阵
mat_from_bus = sparse(mpc.branch(:, 1), 1:bra_num, ones(bra_num, 1), bus_num, bra_num);
mat_to_bus = sparse(mpc.branch(:, 2), 1:bra_num, ones(bra_num, 1), bus_num, bra_num);
mat_gen_bus = sparse(mpc.gen(:, 1), 1:gen_num, ones(gen_num, 1), bus_num, gen_num);
mat_pv_bus = sparse(mpc.pv(:, 1), 1:pv_num, ones(pv_num, 1), bus_num, pv_num);
mat_wind_bus = sparse(mpc.wind(:, 1), 1:wind_num, ones(wind_num, 1), bus_num, wind_num);
mat_storage_bus = sparse(mpc.storage(:, 1), 1:storage_num, ones(storage_num, 1), bus_num, storage_num);

r = mpc.branch(:, 3);
x = mpc.branch(:, 4);
pf_pv = mpc.pv(:, 4);
pf_wind = mpc.wind(:, 4);
pf_storgare = mpc.storage(:, 4);

C = [];

%%% 构建目标函数
%% 1. 投资成本
% gen_inv_cost = sum(mpc.gen(:, 7) ./ ((1 - mpc.gen(:, 8)) .* mpc.gen(:, 9) .* mpc.gen(:, 10)));  % 发电机投资成本
C = [C;
    pv_inv_cost == sum(mpc.pv(:, 6) .* mpc.pv(:, 7) .* vars.S_pv);  % 光伏投资单位容量时间成本
    wind_inv_cost == sum(mpc.wind(:, 6) .* mpc.wind(:, 7) .* vars.S_wind);  % 风电投资单位容量时间成本
    storage_inv_cost == sum(mpc.storage(:, 6) .* vars.E_storage);  % 储能投资单位容量时间成本
];
vars.inv_cost = S_base * 1000 / 365 * (pv_inv_cost + wind_inv_cost + storage_inv_cost);

%% 2. 运行成本
C = [C;
    % gen_run_cost == Sb * sum((3.6 * mpc.gen(:, 11) ./ (mpc.gen(:, 12) .* (1 - mpc.gen(:, 11)))) .* vars.Pg, "all");  % 常规发电成本
    % 发电机主要是预留接口，燃气轮机组不一定会用上
    gen_run_cost == 0;
    pv_run_cost == S_base * 1000 * t * sum(mpc.pv(:, 8) .* vars.P_pv, 'all');  % 光伏发电成本
    wind_run_cost == S_base * 1000 * t * sum(mpc.wind(:, 8) .* vars.P_wind, 'all');  % 风电发电成本
    storage_run_cost == S_base * sum(mpc.storage(:, 7) .* (abs(vars.P_storage_input) + abs(vars.P_storage_output)) * 1000 * t + mpc.storage(:, 8), 'all');  % 储能电站运行成本
    purchase_cost == S_base * 1000 * t * vars.P_gen(gen_num, :) * mpc.price;  % 购电成本
    branch_cost == S_base * 1000 * t * sum(vars.l .* r) * mpc.price;  % 支路功率损耗成本（与电价相关）
];

vars.run_cost = gen_run_cost + pv_run_cost + wind_run_cost + storage_run_cost + purchase_cost + branch_cost;

% 总目标函数
model.objective = vars.run_cost + vars.inv_cost; % 欠考虑

%% 构建约束条件
% 1. 母线电压约束
C = [C;
    mpc.bus(:, 6).^2 <= vars.v <= mpc.bus(:, 5).^2;
];

% 2. 发电机出力约束
C = [C;
    mpc.gen(:, 3) <= vars.P_gen <= mpc.gen(:, 2);   % 有功出力限制
    mpc.gen(:, 5) <= vars.Q_gen <= mpc.gen(:, 4);   % 无功出力限制
    vars.P_gen.^2 + vars.Q_gen.^2 <= mpc.gen(:, 6).^2;  % 容量限制
];

% 3. 光伏出力约束
C = [C;
    mpc.pv(:, 3) <= vars.P_pv <= mpc.pv(:, 2);  % 有功出力限制
    vars.P_pv <= pf_pv .* (vars.S_pv * mpc.pv_time);
    vars.S_pv <= mpc.pv(:, 5) .* vars.tactical_pv;
    sum(vars.tactical_pv) <= 2;
];

% 4. 风电出力约束
C = [C;
    mpc.wind(:, 3) <= vars.P_wind <= mpc.wind(:, 2);  % 有功出力限制
    vars.P_wind <= pf_wind .* (vars.S_wind * mpc.wind_time);
    vars.S_wind <= mpc.wind(:, 5) .* vars.tactical_wind;
    sum(vars.tactical_wind) <= 2;
];

% 5. 储能出力约束
C = [C;
    0 <= vars.P_storage_input <= mpc.storage(:, 2) .* vars.tactical_storage;   % 有功出力限制
    0 <= vars.P_storage_output <= mpc.storage(:, 3) .* vars.tactical_storage;  % 有功出力限制
    vars.state_in + vars.state_out <= 1;     % 选择充放电状态 
    0 <= vars.P_storage_input <= 0.2 * mpc.storage(:, 5) .* vars.state_in;    % 充电功率限制
    0 <= vars.P_storage_output <= 0.2 * mpc.storage(:, 5) .* vars.state_out;  % 放电功率限制
    0.2 * vars.E_storage <= vars.soc <= 0.8 * vars.E_storage;  % 储能电量限制
    vars.soc(:, 1) == 0.5 * vars.E_storage;  % 初始电量
    10 * vars.tactical_storage <= S_base * vars.E_storage <= mpc.storage(:, 5) .* vars.tactical_storage;  % 电量限制
];
for i = 1:time_period_num
    C = [C;
        vars.soc(:, i+1) == ...
            vars.soc(:, i) + ...
            0.9 * vars.P_storage_input(:, i) - ...
            1.11 * vars.P_storage_output(:, i);  % 储能电量约束
    ];
end

% 6. 节点功率平衡约束
C = [C;
    mat_from_bus * vars.P - mat_to_bus * (vars.P - r .* vars.l) == ...
        mat_gen_bus * vars.P_gen + ...
        mat_pv_bus * vars.P_pv + ...
        mat_wind_bus * vars.P_wind + ...
        mat_storage_bus * (vars.P_storage_output - vars.P_storage_input) - ...
        mpc.pd_time;
    mat_from_bus * vars.Q - mat_to_bus * (vars.Q - x .* vars.l) == ...
        mat_gen_bus * vars.Q_gen + ...
        mat_pv_bus * (tan(acos(pf_pv)) .* vars.P_pv) + ...
        mat_wind_bus * (tan(acos(pf_wind)) .* vars.P_wind) + ...
        mat_storage_bus * (tan(acos(pf_storgare)) .* (vars.P_storage_output - vars.P_storage_input)) - ...
        mpc.qd_time;
];

% 7. 支路功率流约束（基于分支流模型的二阶锥约束）
C = [C;
    vars.P.^2 + vars.Q.^2 <= vars.l .* (mat_from_bus' * vars.v);
    mat_to_bus' * vars.v == mat_from_bus' * vars.v - 2 * (r .* vars.P + x .* vars.Q) + (r.^2 + x.^2) .* vars.l;
    0 <= vars.l <= mpc.branch(:, 7).^2;
];

model.constraints = C;

end
