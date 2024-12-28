function [model, vars] = build_model(mpc, conf)
% BUILD_MODEL_YALMIP 使用YALMIP构建基于分支流模型的二阶锥优化模型
% 输入：
%   mpc - 包含网络数据的结构体（所有数据均为标幺值）
% 输出：
%   model - YALMIP优化模型
%   vars - YALMIP决策变量

% 获取系统规模
nb = size(mpc.bus, 1);     % 母线数量
nl = size(mpc.branch, 1);  % 支路数量
ng = size(mpc.gen, 1);     % 发电机数量
ns = size(mpc.solar, 1);   % 光伏数量
% nw = size(mpc.wind, 1);    % 风电数量

%% 定义决策变量
% 电压幅值平方变量
vars.v = sdpvar(nb, conf.time);

% 支路电流平方变量
vars.l = sdpvar(nl, conf.time);

% 支路有功变量 
vars.P = sdpvar(nl, conf.time);

% 支路无功变量
vars.Q = sdpvar(nl, conf.time);

% 发电机出力变量
vars.Pg = sdpvar(ng, conf.time);  % 有功出力
vars.Qg = sdpvar(ng, conf.time);  % 无功出力

% 光伏出力变量
vars.Ps = sdpvar(ns, conf.time);  % 有功出力
vars.Qs = sdpvar(ns, conf.time);  % 无功出力

% 风电出力变量
% vars.Pw = sdpvar(nw, conf.time);  % 有功出力
% vars.Qw = sdpvar(nw, conf.time);  % 无功出力

%% 构建目标函数
% 常规发电成本
gen_cost = 0;
for i = 1:ng
    gen = mpc.gen(i, :);
    gen_cost = gen_cost + gen(7) * vars.Pg(i)^2 + gen(8) * vars.Pg(i) + gen(9);
end

% 可再生能源发电成本
solar_cost = 0;
% wind_cost = sum(mpc.wind(:, 6) .* vars.Pw);

% 储能电站运行成本
storage_cost = 0;

% 总目标函数
model.objective = gen_cost + solar_cost + storage_cost;

%% 构建约束条件
C = [];

% 1. 总线电压约束
for i = 1:nb
    C = [C;
        mpc.bus(i, 8)^2 * ones(1, conf.time) <= vars.v(i, :) <= mpc.bus(i, 7)^2 * ones(1, conf.time)
    ];
end

% 2. 发电机出力约束
for i = 1:ng
    C = [C;
        mpc.gen(i, 3) * ones(1, conf.time) <= vars.Pg(i, :) <= mpc.gen(i, 2) * ones(1, conf.time);    % 有功出力限制
        mpc.gen(i, 5) * ones(1, conf.time) <= vars.Qg(i, :) <= mpc.gen(i, 4) * ones(1, conf.time)
    ];   % 无功出力限制
end

% 3. 光伏出力约束
for i = 1:ns
    C = [C;
        mpc.solar(i, 3) * ones(1, conf.time) <= vars.Ps(i) <= mpc.solar(i, 2) * ones(1, conf.time) ;  % 有功出力限制
        mpc.solar(i, 5) * ones(1, conf.time) <= vars.Qs(i) <= mpc.solar(i, 4) * ones(1, conf.time) 
    ];   % 无功出力限制
end

% 4. 风电出力约束
% for i = 1:nw
%     wind = mpc.wind(i, :);
%     C = [C;
%         0 <= vars.Pw(i) <= wind(2) * wind(3);    % 有功出力限制
%         wind(5) <= vars.Qw(i) <= wind(4)
%     ];     % 无功出力限制
% end

% 5. 支路功率流约束（基于分支流模型的二阶锥约束）
for i = 1:nl
    branch = mpc.branch(i, :);
    from_bus = branch(1);
    to_bus = branch(2);
    
    % 二阶锥约束
    C = [C;
        
    ];
    
    % 支路容量约束
    C = [C;
        
    ];
end

% 6. 节点功率平衡约束
for i = 1:nb
    % 获取连接到节点i的所有支路
    [from_lines, to_lines] = get_connected_lines(mpc, i);
    
    % 有功功率平衡
    P_gen = sum(vars.Pg(mpc.gen(:, 1) == i));          % 发电机出力
    P_solar = sum(vars.Ps(mpc.solar(:, 1) == i));      % 光伏出力
    P_wind = sum(vars.Pw(mpc.wind(:, 1) == i));        % 风电出力
    P_load = mpc.bus(i, 3);                            % 负荷功率
    
    % 支路功率流
    P_flow = 0;
    for j = from_lines
        branch = mpc.branch(j, :);
        r = branch(3);
        x = branch(4);
        z2 = r^2 + x^2;
        P_flow = P_flow + (vars.v(i) - vars.v(branch(2))) * r / z2;
    end
    for j = to_lines
        branch = mpc.branch(j, :);
        r = branch(3);
        x = branch(4);
        z2 = r^2 + x^2;
        P_flow = P_flow + (vars.v(i) - vars.v(branch(1))) * r / z2;
    end
    
    % 有功功率平衡约束
    C = [C;
        P_gen + P_solar + P_wind - P_load == P_flow
    ];
    
    % 无功功率平衡约束
    Q_gen = sum(vars.Qg(mpc.gen(:, 1) == i));
    Q_solar = sum(vars.Qs(mpc.solar(:, 1) == i));
    Q_wind = sum(vars.Qw(mpc.wind(:, 1) == i));
    Q_load = mpc.bus(i, 4);
    
    Q_flow = 0;
    for j = from_lines
        branch = mpc.branch(j, :);
        r = branch(3);
        x = branch(4);
        z2 = r^2 + x^2;
        Q_flow = Q_flow + (vars.v(i) - vars.v(branch(2))) * x / z2;
    end
    for j = to_lines
        branch = mpc.branch(j, :);
        r = branch(3);
        x = branch(4);
        z2 = r^2 + x^2 ;
        Q_flow = Q_flow + (vars.v(i) - vars.v(branch(1))) * x / z2;
    end
    
    C = [C;
        Q_gen + Q_solar + Q_wind - Q_load == Q_flow
    ];
end

% 保存约束条件
model.constraints = C;

end
