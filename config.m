function conf = config()
% CONFIG 配置文件，用于设置潮流计算的参数
% 用户可以修改此文件中的参数来控制计算过程
% 返回值：
%   conf - 包含所有配置参数的结构体

%% 基准值设置
conf.base.S = 10;        % 基准容量
conf.base.U = 12.66;     % 基准电压

%% 优化器设置
conf.solver.name = 'cplex';    % 求解器选择：'cplex', 'gurobi'等
conf.solver.max_time = 3600;   % 最大求解时间（秒）
conf.solver.gap_tol = 1e-2;    % 收敛容差
conf.solver.verbose = 3;       % 是否显示求解细节（0-3）

%% 案例文件选择
conf.network.case_file = 'case33_3.m';

%% 时段数量设置
conf.time = 24; % 1为不考虑时段变化，24为一天24小时的时段变化。建议只使用1和24两个值。

%% 场景设置
conf.scenarios = 3; % 定义场景数量，例如 3 个典型场景

%% 结果输出设置
conf.output.save_results = false;    % 是否保存结果到文件
conf.output.result_path = 'results'; % 结果保存路径

end