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
    results.Qg = value(vars.Qg);          % 发电机无功出力
    results.Ps = value(vars.Ps);          % 光伏有功出力
    results.Pw = value(vars.Pw);          % 风电有功出力
    results.Pst_in = value(vars.Pst_in);  % 储能电站充电功率
    results.Pst_out = value(vars.Pst_out);% 储能电站放电功率
    results.soc = value(vars.soc);        % 储能电站荷电状态
    results.inv_cost = vars.inv_cost;     % 投资成本
    results.obj = value(model.objective); % 目标函数值
    
    % 显示结果
    display_results(results, conf);
    
    % 保存结果
    if conf.output.save_results
        if ~exist(conf.output.result_path, 'dir')
            mkdir(conf.output.result_path);
        end
        save(fullfile(conf.output.result_path, 'results.mat'), 'results', 'mpc', 'conf');
    end
    
    % 绘制结果图
    if conf.output.plot_voltage
        plot_voltage_profile(results, mpc);
    end
    if conf.output.plot_power
        plot_power_flow(results, mpc);
    end
else
    disp('优化求解失败！');
    disp(['求解状态: ' solve.info]);
end
