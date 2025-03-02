function display_results(results, mpc, conf)
% DISPLAY_RESULTS 显示优化结果
% 输入：
%   results - 优化结果结构体
%   mpc - 包含网络数据的结构体

% 显示目标函数值
fprintf('\n优化结果：\n');
fprintf('总成本: %.2f 元\n', results.obj);
fprintf('投资成本: %.2f 元\n', results.inv_cost);
fprintf('运行成本: %.2f 元\n', results.run_cost);

% 显示电压结果
figure('Name', '电压幅值');
if conf.time == 24
    fprintf('节点电压幅值(p.u.)三维图\n');
    bar3(sqrt(results.v));
    fprintf('节点电压幅值(p.u.)数据如下\n');
    disp(sqrt(results.v));
elseif conf.time == 1
    fprintf('节点电压幅值(p.u.)图\n');
    bar(1:size(results.v, 1), sqrt(results.v));
end


% 显示支路有功功率
figure('Name', '支路有功功率');
if conf.time == 24
    fprintf('支路有功功率(p.u.)三维图\n');
    bar3(results.P);
    fprintf('支路有功功率(p.u.)数据如下\n');
    disp(results.P);
elseif conf.time == 1
    fprintf('支路有功功率(p.u.)图\n');
    bar(1:size(results.P, 1), results.P);
end


% 显示发电机出力
if mpc.flag.gen
    figure('Name', '发电机有功功率');
    if conf.time == 24
        fprintf('\n发电机有功功率(p.u)三维图\n');
        bar3(results.Pg);
        fprintf('发电机有功功率(p.u.)数据如下\n');
        disp(results.Pg);
    elseif conf.time == 1
        fprintf('发电机有功功率(p.u.)图\n');
        bar(results.Pg);
    end
end

% 显示光伏出力
if mpc.flag.solar
    figure('Name', '光伏有功功率');
    if conf.time == 24
        fprintf('\n光伏有功功率(p.u)三维图\n');
        bar3(results.Ps);
        fprintf('光伏有功功率(p.u.)数据如下\n');
        disp(results.Ps);
    elseif conf.time == 1
        fprintf('光伏有功功率(p.u.)图\n');
        bar(results.Ps);
    end
end

% 显示风电出力
if mpc.flag.wind
    figure('Name', '风电有功功率');
    if conf.time == 24
        fprintf('\n风电有功功率(p.u)三维图\n');
        bar3(results.Pw);
        fprintf('风电有功功率(p.u.)数据如下\n');
        disp(results.Pw);
    elseif conf.time == 1
        fprintf('风电有功功率(p.u.)图\n');
        bar(1:size(results.Pw, 1), results.Pw);
    end
end

% 显示储能电站充放电功率
if mpc.flag.storage
    figure('Name', '储能电站充放电功率');
    if conf.time == 24
        fprintf('\n储能电站充放电功率(p.u)三维图\n');
        bar3(results.Pst);
        fprintf('储能电站充放电功率(p.u.)数据如下\n');
        disp(results.Pst);
    elseif conf.time == 1
        fprintf('储能电站充放电功率(p.u.)图\n');
        bar(1:size(results.Pst, 1), results.Pst);
    end
end 