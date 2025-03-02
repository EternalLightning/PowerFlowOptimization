clear;
clc;

% 加载配置参数
conf = config();

% 导入数据
mpc = network_data(conf);

% 构建YALMIP优化模型
[model, vars] = build_model(mpc, conf);

% 设置求解器选项
options = sdpsettings('solver', conf.solver.name, ...
                     'verbose', conf.solver.verbose, ...
                     'showprogress', conf.solver.verbose, ...
                     [conf.solver.name '.timelimit'], conf.solver.max_time);


solve = optimize(model.constraints, model.objective, options);


if solve.problem == 0
    results.v = value(vars.v);            % 母线电压幅值平方
    results.l = value(vars.l);            % 支路电流平方
    results.P = value(vars.P);            % 支路有功功率
    results.Q = value(vars.Q);            % 支路无功功率
    results.Pg = value(vars.Pg(1:end-1, :));          % 发电机有功出力
    results.Qg = value(vars.Qg(1:end-1, :));          % 发电机无功出力
    results.Ps = value(vars.Ps);          % 光伏有功出力
    results.Ss = value(vars.Ss);          % 光伏容量
    results.Pw = value(vars.Pw);          % 风电有功出力
    results.Sw = value(vars.Sw);          % 风电容量
    results.Pst = value(vars.Pst_out) - value(vars.Pst_in);  % 储能电站充放电功率
    results.soc = value(vars.soc);        % 储能电站荷电状态
    results.inv_cost = value(vars.inv_cost);     % 投资成本
    results.run_cost = value(vars.run_cost);     % 运行成本
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
