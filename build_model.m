function [model, vars] = build_model(mpc, conf)
% BUILD_MODEL_YALMIP 使用YALMIP构建基于分支流模型的二阶锥优化模型
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

%% 定义决策变量
vars.v = sdpvar(nb, conf.time);     % 电压幅值平方变量
vars.l = sdpvar(nl, conf.time);     % 支路电流平方变量
vars.P = sdpvar(nl, conf.time);     % 支路有功变量
vars.Q = sdpvar(nl, conf.time);     % 支路无功变量
vars.Pg = sdpvar(ng, conf.time);    % 发电机有功出力
vars.Qg = sdpvar(ng, conf.time);    % 发电机无功出力
vars.Ps = sdpvar(ns, conf.time);    % 光伏有功出力
vars.Qs = sdpvar(ns, conf.time);    % 光伏无功出力
vars.Pw = sdpvar(nw, conf.time);    % 风电有功出力
vars.Qw = sdpvar(nw, conf.time);    % 风电无功出力
vars.Pst = sdpvar(nst, conf.time);  % 储能有功出力
vars.Qst = sdpvar(nst, conf.time);  % 储能无功出力

%% 构建关联矩阵
mat_fbus = sparse(mpc.branch(:, 1), 1:nl, ones(nl, 1), nb, nl);
mat_tbus = sparse(mpc.branch(:, 2), 1:nl, ones(nl, 1), nb, nl);
mat_gbus = sparse(mpc.gen(:, 1), 1:ng, ones(ng, 1), nb, ng);
mat_sbus = sparse(mpc.solar(:, 1), 1:ns, ones(ng, 1), nb, ns);
mat_wbus = sparse(mpc.wind(:, 1), 1:nw, ones(nw, 1), nb, nw);
mat_stbus = sparse(mpc.storage(:, 1), 1:nst, ones(nst, 1), nb, nst);

r = mpc.branch(:, 3);
x = mpc.branch(:, 4);

%%% 构建目标函数
%% 1. 投资成本

% 常规发电成本
gen_cost = sum(mpc.gen(:, 7) .* vars.Pg.^2 + mpc.gen(:, 8) .* vars.Pg + mpc.gen(:, 9))';

 
% 可再生能源发电成本
solar_cost = sum(mpc.solar(:, 6) .* mpc.solar(:, 7) .* vars.Ps * 1000 * 24 / (365 * conf.time))';
wind_cost = sum(mpc.wind(:, 6) .* mpc.wind(:, 7) .* vars.Pw * 1000 * 24 / (365 * conf.time))';

% 储能电站运行成本
storage_cost = zeros(conf.time, 1);
for j = 1:conf.time
    for i = 1:nst
        storage_cost(j) = storage_cost(j) + mpc.storage(6) * mpc.storage(5) + mpc.storage(7) * vars.Pst(i, j) * 1000 * 24 / conf.time + mpc.storage(8);
    end
end


%% 2. 运行成本
% 购电成本
purchase_cost = vars.Pg(ng, :)' * 1000 .* mpc.price * 24 / conf.time;

% 支路功率损耗成本（与电价相关）
branch_cost = sum(vars.l .* r .* mpc.price')';

% 总目标函数
model.objective = gen_cost + solar_cost + wind_cost + storage_cost + branch_cost + purchase_cost;

%% 构建约束条件
C = [];

% 1. 总线电压约束
C = [C;
    mpc.bus(:, 6).^2 <= vars.v <= mpc.bus(:, 5).^2
]


% 2. 发电机出力约束
C = [C;
    mpc.gen(:, 3) <= vars.Pg <= mpc.gen(:, 2);  % 有功出力限制
    mpc.gen(:, 5) <= vars.Qg <= mpc.gen(:, 4);  % 无功出力限制
    vars.Pg.^2 + var.Qg.^2 <= mpc.gen(:, 6).^2  % 容量限制
];


% 3. 光伏出力约束
C = [C;
    mpc.solar(:, 3) <= vars.Ps <= mpc.solar(:, 2);      % 有功出力限制
    0 <= vars.Ps <= mpc.solar(:, 5) .* mpc.solar(:, 4)  % 容量限制
];


% 4. 风电出力约束
C = [C;
    mpc.wind(:, 3) <= vars.Pw <= mpc.wind(:, 2);      % 有功出力限制
    0 <= vars.Pw <= mpc.wind(:, 5) .* mpc.wind(:, 4)  % 容量限制
];


% 5. 储能出力约束
C = [C;
    mpc.storage(:, 3) <= vars.Pst <= mpc.storage(:, 2);      % 有功出力限制
    abs(vars.Pst) <= mpc.storage(:, 5) .* mpc.storage(:, 4)  % 容量限制
];

% 6. 节点功率平衡约束
p_j = mat_gbus * vars.Pg + mat_sbus * vars.Ps + mat_wbus * vars.Pw + mat_stbus * vars.Pst;
q_j = mat_gbus * vars.Qg + mat_sbus * vars.Qs + mat_wbus * vars.Qw + mat_stbus * vars.Qst;
C = [C;
    p_j == mat_tbus * vars.P - mat_fbus * (vars.P - vars.l .* r);
    q_j == mat_tbus * vars.Q - mat_fbus * (vars.Q - vars.l .* x);
]


% 7. 支路功率流约束（基于分支流模型的二阶锥约束）
C = [C;
    vars.P.^2 + vars.Q.^2 <= vars.l .* (mat_fbus' * vars.v);  % 能写成cone([a, b; x, y])吗？感觉意义不大，计算差不了几秒。
    mat_tbus' * vars.v = mat_fbus' * vars.v - 2 * (r .* vars.P + x .* vars.Q) + (r.^2 + x.^2) * vars.l;
    vars.v >= 0;
    vars.l >= 0;
];


% 保存约束条件
model.constraints = C;

end
