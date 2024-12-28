function display_results(results, mpc)
% DISPLAY_RESULTS 显示优化结果
% 输入：
%   results - 优化结果结构体
%   mpc - 包含网络数据的结构体

% 显示目标函数值
fprintf('\n优化结果：\n');
fprintf('总成本: %.2f $\n', results.obj);

% 显示电压结果
fprintf('\n节点电压：\n');
fprintf('节点\t幅值(p.u.)\n');
for i = 1:length(results.v)
    fprintf('%d\t%.4f\n', i, results.v(i));
end

% 显示发电机出力
fprintf('\n发电机出力：\n');
fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
for i = 1:length(results.Pg)
    fprintf('%d\t%.4f\t\t%.4f\n', mpc.gen(i, 1), results.Pg(i), results.Qg(i));
end

% 显示光伏出力
if ~isempty(results.Ps)
    fprintf('\n光伏出力：\n');
    fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
    for i = 1:length(results.Ps)
        fprintf('%d\t%.4f\t\t%.4f\n', mpc.solar(i, 1), results.Ps(i), results.Qs(i));
    end
end

% 显示风电出力
if ~isempty(results.Pw)
    fprintf('\n风电出力：\n');
    fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
    for i = 1:length(results.Pw)
        fprintf('%d\t%.4f\t\t%.4f\n', mpc.wind(i, 1), results.Pw(i), results.Qw(i));
    end
end

% 显示支路电流
fprintf('\n支路电流：\n');
fprintf('从节点\t到节点\t电流(p.u.)\n');
for i = 1:length(results.l)
    fprintf('%d\t%d\t%.4f\n', mpc.branch(i, 1), mpc.branch(i, 2), sqrt(results.l(i)));
end

end 