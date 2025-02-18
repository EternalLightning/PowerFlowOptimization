function conf = config()
% CONFIG 配置文件，用于设置潮流计算的参数
% 用户可以修改此文件中的参数来控制计算过程
% 返回值：
%   conf - 包含所有配置参数的结构体

%% 基准值设置
conf.base.S = 100;        % 基准容量，默认100MVA
conf.base.U = 33;         % 基准电压，默认33kV

%% 优化器设置
conf.solver.name = 'cplex';    % 求解器选择：'cplex', 'gurobi'等
conf.solver.max_time = 3600;   % 最大求解时间（秒）
conf.solver.gap_tol = 1e-4;    % 收敛容差
conf.solver.verbose = 0;       % 是否显示求解细节（0-3）

%% 案例文件选择
conf.network.case_file = 'case33.m';

%% 网络拓扑选择
conf.network.topology = 'ieee33';  % 可选: 'ieee33', 'ieee123', 'custom', 如果为'custom'，需在自定义案例文件中定义网络结构

%% 时段数量设置
conf.time = 24; % 1为不考虑时段变化，24为一天24小时的时段变化。建议只使用1和24两个值。

%% 结果输出设置
conf.output.save_results = false;    % 是否保存结果到文件
conf.output.result_path = 'results'; % 结果保存路径
conf.output.plot_voltage = true;     % 是否绘制电压分布图
conf.output.plot_power = true;       % 是否绘制功率分布图

end 