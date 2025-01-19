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
nw = size(mpc.wind, 1);    % 风电数量
nst = size(mpc.storage, 1);

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
vars.Pw = sdpvar(nw, conf.time);  % 有功出力
vars.Qw = sdpvar(nw, conf.time);  % 无功出力

% 风电出力变量
vars.Pst = sdpvar(nst, conf.time);  % 有功出力
vars.Qst = sdpvar(nst, conf.time);  % 无功出力

%% 构建目标函数
% 常规发电成本
gen_cost = zeros(conf.time, 1);
for i = 1:ng - 1
    gen = mpc.gen(i, :);
    for j = 1:conf.time
        gen_cost(j) = gen_cost(j) + gen(7) * vars.Pg(i, j)^2 + gen(8) * vars.Pg(i, j) + gen(9);
    end
end

% 支路功率损耗成本（与电价相关）
branch_cost = zeros(conf.time, 1);
for i = 1:nl
    for j = 1:conf.time
        branch_cost(j) = branch_cost(j) + vars.l * mpc.branch(i, 3) * mpc.price(j);
    end
end
 
% 可再生能源发电成本
solar_cost = zeros(conf.time, 1);
for j = 1:conf.time
    for i = 1:ns
        solar_cost(j) = solar_cost(j) + mpc.solar(6) * mpc.solar(7) * vars.Ps(i, j) * 1000 * 24 / (365 * conf.time);
    end
end


wind_cost = zeros(conf.time, 1);
for j = 1:conf.time
    for i = 1:nw
        wind_cost(j) = wind_cost(j) + mpc.wind(6) * mpc.wind(7) * vars.Pw(i, j) * 1000 * 24 / (365 * conf.time);
    end
end

% 储能电站运行成本
storage_cost = zeros(conf.time, 1);
for j = 1:conf.time
    for i = 1:nst
        storage_cost(j) = storage_cost(j) + mpc.storage(6) * mpc.storage(5) + mpc.storage(7) * vars.Pst(i, j) * 1000 * 24 / conf.time + mpc.storage(8);
    end
end

% 购电成本
purchase_cost = zeros(conf.time, 1);
for j = 1:conf.time
    purchase_cost(j) = vars.Pg(ng, j) * 1000 * mpc.price(j) * 24 / conf.time;
end


% 总目标函数
model.objective = gen_cost + solar_cost + wind_cost + storage_cost + branch_cost + purchase_cost;

%% 构建约束条件
C = [];

% 1. 总线电压约束
for i = 1:nb
    C = [C;
        mpc.bus(i, 6)^2 * ones(1, conf.time) <= vars.v(i, :) <= mpc.bus(i, 5)^2 * ones(1, conf.time)
    ];
end

% 2. 发电机出力约束
for i = 1:ng
    C = [C;
        mpc.gen(i, 3) * ones(1, conf.time) <= vars.Pg(i, :) <= mpc.gen(i, 2) * ones(1, conf.time);  % 有功出力限制
        mpc.gen(i, 5) * ones(1, conf.time) <= vars.Qg(i, :) <= mpc.gen(i, 4) * ones(1, conf.time);  % 无功出力限制
        vars.Pg(i, :).^2 + var.Qg(i, :).^2 <= mpc.gen(i, 6)^2 * ones(1, conf.time)  % 容量限制
    ];
end

% 3. 光伏出力约束
for i = 1:ns
    C = [C;
        mpc.solar(i, 3) * ones(1, conf.time) <= vars.Ps(i, :) <= mpc.solar(i, 2) * ones(1, conf.time);  % 有功出力限制
        zeros(1, conf.time) <= vars.Ps(i, :) / mpc.solar(i, 4) <= mpc.solar(i, 5) * ones(1, conf.time)
    ];
end

% 4. 风电出力约束
for i = 1:nw
    C = [C;
        mpc.wind(i, 3) * ones(1, conf.time) <= vars.Pw(i, :) <= mpc.wind(i, 2) * ones(1, conf.time);  % 有功出力限制
        zeros(1, conf.time) <= vars.Pw(i, :) / mpc.wind(i, 4) <= mpc.wind(i, 5) * ones(1, conf.time)
    ];
end

% 5. 储能出力约束
for i = 1:nst
    C = [C;
        mpc.storage(i, 3) * ones(1, conf.time) <= vars.Pst(i, :) <= mpc.storage(i, 2) * ones(1, conf.time);  % 有功出力限制
        -mpc.storage(i, 5) * ones(1, conf.time) <= vars.Pst(i, :) / mpc.storage(i, 4) <= mpc.storage(i, 5) * ones(1, conf.time)
    ];
end

% 6. 节点功率平衡约束
for bus_num = 1:nb
    % 获取连接到节点i的所有支路**索引**
    [from_lines, to_lines] = get_connected_lines(mpc, bus_num);
    gens = find(mpc.gen(:, 1) == bus_num);
    solars = find(mpc.solar(:, 1) == bus_num);
    winds = find(mpc.wind(:, 1) == bus_num);
    storages = find(mpc.storage(:, 1) == bus_num);

    for j = 1:conf.time
        % 有功功率平衡
        P_gen = sum(vars.Pg(gens, j));          % 发电机出力
        P_solar = sum(vars.Ps(solars, j));      % 光伏出力
        P_wind = sum(vars.Pw(winds, j));        % 风电出力
        P_storage = sum(vars.Pst(storages, j));     % 储能出力
        P_load = mpc.pd_time(bus_num, j);       % 负荷功率

        r = mpc.branch(i, 3);
        x = mpc.branch(i, 4);

        % 支路功率流
        P_flow = 0;
        for k = from_lines
            P_flow = P_flow + vars.P(k, j) - vars.l * r;
        end
        for k = to_lines
            P_flow = P_flow - vars.P(k, j);
        end
        
        % 有功功率平衡约束
        C = [C;
            P_gen + P_solar + P_wind + P_flow + P_storage == P_load;
        ];
        
        % 无功功率平衡约束
        Q_gen = sum(vars.Qg(gens, j));
        Q_solar = sum(vars.Qs(solars, j));
        Q_wind = sum(vars.Qw(winds, j));
        Q_storage = sum(vars.Qst(storages, j));
        Q_load = mpc.qd_time(bus_num, j);
        
        Q_flow = 0;
        for k = from_lines
            Q_flow = Q_flow + vars.Q(k, j) - vars.l * x;
        end
        for k = to_lines
            Q_flow = Q_flow - vars.Q(k, j);
        end
        
        C = [C;
            Q_gen + Q_solar + Q_wind + Q_flow + Q_storage == Q_load;
        ];
    end
end

% 7. 支路功率流约束（基于分支流模型的二阶锥约束）
for i = 1:nl
    from_bus = mpc.branch(i, 1);
    to_bus = mpc.branch(i, 2);
    r = mpc.branch(i, 3);
    x = mpc.branch(i, 4);

    for j = 1:conf.time
        % 二阶锥约束
        C = [C;
            cone([2 * vars.P(i, j), 2 * vars.Q(i, j), vars.l(i, j) - vars.v(from_bus)], vars.l(i, j) + vars.v(from_bus));
        ];
        
        % 支路负荷约束
        C = [C;
            vars.v(to_bus) = vars.v(from_bus) - 2 * (r * vars.P(i, j) + x * vars.Q(i, j)) + (r^2 + x^2) * vars.l(i, j);
        ];
    end
end

% 保存约束条件
model.constraints = C;

end
