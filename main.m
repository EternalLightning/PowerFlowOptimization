clear;
clc;

% 加载配置参数
conf = config();

% 导入数据
mpc = data_check(conf);

% 构建YALMIP优化模型
[model, vars] = build_model(mpc, conf);

% 设置求解器选项
options = sdpsettings('solver', conf.solver.name, ...
                     'verbose', conf.solver.verbose, ...
                     'showprogress', conf.solver.verbose, ...
                     [conf.solver.name '.timelimit'], conf.solver.max_time);


solve = optimize(model.constraints, model.objective, options);


if solve.problem == 0
    results.v = value(vars.v);             % 母线电压幅值平方
    results.l = value(vars.l);             % 支路电流平方
    results.P = value(vars.P);             % 支路有功功率
    results.Q = value(vars.Q);             % 支路无功功率
    results.P_trans = value(vars.P_trans); % 上级变压器传输有功
    results.Q_trans = value(vars.Q_trans); % 上级变压器传输无功
    results.P_gen = value(vars.P_gen);     % 发电机有功出力
    results.Q_gen = value(vars.Q_gen);     % 发电机无功出力
    results.P_pv = value(vars.P_pv);       % 光伏有功出力
    results.S_pv = value(vars.S_pv);       % 光伏容量
    results.P_wind = value(vars.P_wind);   % 风电有功出力
    results.S_wind = value(vars.S_wind);   % 风电容量
    results.P_ess = value(vars.P_ess_out) - value(vars.P_ess_in);  % 储能电站充放电功率
    results.soc = value(vars.soc);           % 储能电站荷电状态
    results.inv_cost = value(vars.inv_cost); % 投资成本
    results.run_cost = value(vars.run_cost); % 运行成本
    results.tactical_wind = value(vars.tactical_wind);  % 风电作业层决策
    results.tactical_pv = value(vars.tactical_pv);      % 光伏作业层决策
    results.tactical_ess = value(vars.tactical_ess);  % 储能作业层决策
    results.obj = value(model.objective); % 目标函数值
    
    % 显示结果
    display_results(results, mpc, conf);
    
    % 保存结果
    if conf.output.save_results
        if ~exist(conf.output.result_path, 'dir')
            mkdir(conf.output.result_path);
        end
        save(fullfile(conf.output.result_path, 'results.mat'), 'results', 'mpc', 'conf');
    end
else
    disp('优化求解失败！');
    disp(['求解状态: ' solve.info]);
end
