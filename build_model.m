function [model, vars] = build_model(mpc, conf)
% BUILD_MODEL 使用YALMIP构建基于分支流模型的二阶锥优化模型
% 输入：
%   mpc - 包含网络数据的结构体（所有数据均为标幺值）
% 输出：
%   model - YALMIP优化模型
%   vars - YALMIP决策变量

%% 获取系统规模
nb = size(mpc.bus, 1);       % 母线数量
nl = size(mpc.branch, 1);    % 支路数量
ng = size(mpc.gen, 1);       % 发电机数量
ns = size(mpc.solar, 1);     % 光伏数量
nw = size(mpc.wind, 1);      % 风电数量
nst = size(mpc.storage, 1);  % 储能数量
nt = conf.time;              % 时段数量
t = 24 / nt;                 % 每个时段的小时数
Sb = conf.base.S;            % 容量基准值
Ub = conf.base.U;            % 电压基准值

%% 定义决策变量
vars.v = sdpvar(nb, nt);     % 电压幅值平方变量
vars.l = sdpvar(nl, nt);     % 支路电流平方变量
vars.P = sdpvar(nl, nt);     % 支路有功变量
vars.Q = sdpvar(nl, nt);     % 支路无功变量
vars.Pg = sdpvar(ng, nt);    % 发电机有功出力
vars.Qg = sdpvar(ng, nt);    % 发电机无功出力
vars.Ps = sdpvar(ns, nt);    % 光伏有功出力
vars.Pw = sdpvar(nw, nt);    % 风电有功出力
vars.Pst_in = sdpvar(nst, nt);  % 储能有功输入
vars.Pst_out = sdpvar(nst, nt); % 储能有功输出
vars.state_in = binvar(nst, nt);  % 储能充电状态
vars.state_out = binvar(nst, nt); % 储能放电状态
vars.soc = sdpvar(nst, nt + 1);   % 储能电量
gen_run_cost = sdpvar(1, nt);  % 发电机运行成本
solar_run_cost = sdpvar(1, nt);  % 光伏运行成本
wind_run_cost = sdpvar(1, nt);  % 风电运行成本
storage_run_cost = sdpvar(1, nt);  % 储能运行成本
purchase_cost = sdpvar(1, nt);  % 购电成本
branch_cost = sdpvar(1, nt);  % 支路功率损耗成本

%% 构建关联矩阵
mat_fbus = sparse(mpc.branch(:, 1), 1:nl, ones(nl, 1), nb, nl);
mat_tbus = sparse(mpc.branch(:, 2), 1:nl, ones(nl, 1), nb, nl);
mat_gbus = sparse(mpc.gen(:, 1), 1:ng, ones(ng, 1), nb, ng);
mat_sbus = sparse(mpc.solar(:, 1), 1:ns, ones(ns, 1), nb, ns);
mat_wbus = sparse(mpc.wind(:, 1), 1:nw, ones(nw, 1), nb, nw);
mat_stbus = sparse(mpc.storage(:, 1), 1:nst, ones(nst, 1), nb, nst);

r = mpc.branch(:, 3);
x = mpc.branch(:, 4);
pf_s = mpc.solar(:, 4);
pf_w = mpc.wind(:, 4);
pf_st = mpc.storage(:, 4);

C = [];

%%% 构建目标函数
%% 1. 投资成本
gen_inv_cost = sum(mpc.gen(:, 7) ./ ((1 - mpc.gen(:, 8)) .* mpc.gen(:, 9) .* mpc.gen(:, 10)));  % 发电机投资成本
solar_inv_cost = sum(mpc.solar(:, 6) .* mpc.solar(:, 7) .* mpc.solar(:, 5) * 1000 / 365);  % 光伏投资成本
wind_inv_cost = sum(mpc.wind(:, 6) .* mpc.wind(:, 7) .* mpc.wind(:, 5) * 1000 / 365);  % 风电投资成本
storage_inv_cost = sum(mpc.storage(:, 5) .* mpc.storage(:, 6) * 1000 / 365);  % 储能投资成本
vars.inv_cost = gen_inv_cost + solar_inv_cost + wind_inv_cost + storage_inv_cost;

%% 2. 运行成本
C = [C;
    gen_run_cost == Sb * sum((3.6 * mpc.gen(:, 11) ./ (mpc.gen(:, 12) .* (1 - mpc.gen(:, 11)))) .* vars.Pg);  % 常规发电成本
    solar_run_cost == Sb * sum(mpc.solar(:, 8) .* vars.Ps * 1000 * t);  % 光伏发电成本
    wind_run_cost == Sb * sum(mpc.wind(:, 8) .* vars.Pw * 1000 * t);  % 风电发电成本
    storage_run_cost == Sb * sum(mpc.storage(:, 7) .* (abs(vars.Pst_in) + abs(vars.Pst_out)) * 1000 * t + mpc.storage(:, 8));  % 储能电站运行成本
    purchase_cost == Sb * 1000 * t * vars.Pg(ng, :) .* mpc.price';  % 购电成本
    branch_cost == Sb * 1000 * t * sum(vars.l .* r .* mpc.price');  % 支路功率损耗成本（与电价相关）
];

run_cost = gen_run_cost + solar_run_cost + wind_run_cost + storage_run_cost + purchase_cost + branch_cost;

% 总目标函数
model.objective = sum(run_cost); % 欠考虑

%% 构建约束条件
% 1. 母线电压约束
C = [C;
    mpc.bus(:, 6).^2 <= vars.v <= mpc.bus(:, 5).^2;
];

% 2. 发电机出力约束
C = [C;
    mpc.gen(:, 3) <= vars.Pg <= mpc.gen(:, 2);   % 有功出力限制
    mpc.gen(:, 5) <= vars.Qg <= mpc.gen(:, 4);   % 无功出力限制
    vars.Pg.^2 + vars.Qg.^2 <= mpc.gen(:, 6).^2;  % 容量限制
];

% 3. 光伏出力约束
C = [C;
    mpc.solar(:, 3) <= vars.Ps <= mpc.solar(:, 2);  % 有功出力限制
    0 <= vars.Ps <= mpc.solar(:, 5) .* pf_s;        % 容量限制
    vars.Ps <= mpc.solar(:, 5) .* mpc.solar_time;   % 日出力限制
];

% 4. 风电出力约束
C = [C;
    mpc.wind(:, 3) <= vars.Pw <= mpc.wind(:, 2);  % 有功出力限制
    0 <= vars.Pw <= mpc.wind(:, 5) .* pf_w;       % 容量限制
    vars.Pw <= mpc.wind(:, 5) .* mpc.wind_time;   % 日出力限制
];

% 5. 储能出力约束
C = [C;
    0 <= vars.Pst_in <= mpc.storage(:, 2);   % 有功出力限制
    0 <= vars.Pst_out <= mpc.storage(:, 3);  % 有功出力限制
    vars.state_in + vars.state_out <= 1;     % 选择充放电状态
    0 <= vars.Pst_in <= 0.2 * mpc.storage(:, 5) .* vars.state_in;    % 充电功率限制
    0 <= vars.Pst_out <= 0.2 * mpc.storage(:, 5) .* vars.state_out;  % 放电功率限制
];
for i = 1:nt
    C = [C;
        vars.soc(:, i+1) == vars.soc(:, i) + 0.9 * vars.Pst_in(:, i) - 1.11 * vars.Pst_out(:, i);  % 储能电量约束
    ];
end

% 6. 节点功率平衡约束
C = [C;
    mat_fbus * vars.P - mat_tbus * (vars.P - r .* vars.l) == mat_gbus * vars.Pg + ...
        mat_sbus * vars.Ps + mat_wbus * vars.Pw + mat_stbus * (vars.Pst_out - vars.Pst_in) - mpc.pd_time;
    mat_fbus * vars.Q - mat_tbus * (vars.Q - x .* vars.l) == mat_gbus * vars.Qg + mat_sbus * (tan(acos(pf_s)) .* vars.Ps) + ...
        mat_wbus * (tan(acos(pf_w)) .* vars.Pw) + mat_stbus * (tan(acos(pf_st)) .* (vars.Pst_out - vars.Pst_in)) - mpc.qd_time;
];

% 7. 支路功率流约束（基于分支流模型的二阶锥约束）
C = [C;
    vars.P.^2 + vars.Q.^2 <= vars.l .* (mat_fbus' * vars.v);
    mat_tbus' * vars.v == mat_fbus' * vars.v - 2 * (r .* vars.P + x .* vars.Q) + (r.^2 + x.^2) .* vars.l;
    0 <= vars.l <= mpc.branch(:, 7).^2;
];

model.constraints = C;

end
