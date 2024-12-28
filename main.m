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
                     [conf.solver.name '.timelimit'], conf.solver.max_time, ...
                     [conf.solver.name '.mipgap'], conf.solver.gap_tol);


solve = optimize(model.constraints, model.objective, options);


if solve.problem == 0
    results.Pg = value(vars.Pg);      % 发电机有功出力
    results.Qg = value(vars.Qg);      % 发电机无功出力
    results.Ps = value(vars.Ps);      % 光伏有功出力
    results.Qs = value(vars.Qs);      % 光伏无功出力
    results.Pw = value(vars.Pw);      % 风电有功出力
    results.Qw = value(vars.Qw);      % 风电无功出力
    results.obj = value(model.objective); % 目标函数值
    
    % 显示结果
    display_results(results, mpc);
    
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
