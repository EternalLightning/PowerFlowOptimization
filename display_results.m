function display_results(results, mpc)
% DISPLAY_RESULTS 显示优化结果
% 输入：
%   results - 优化结果结构体
%   mpc - 包含网络数据的结构体

% 显示目标函数值
fprintf('\n优化结果：\n');
fprintf('总成本: %.2f 元\n', results.obj);

results.Ps

results.Pw

% 显示电压结果
% fprintf('\n节点电压：\n');
% fprintf('节点\t幅值(p.u.)\n');
% for i = 1:size(results.v, 1)
%     fprintf('%d\t%.4f\n', i, sqrt(results.v(i)));
% end

% 显示支路功率
% fprintf('\n支路功率：\n');
% fprintf('支路\t有功(p.u.)\t无功(p.u.)\n');
% for i = 1:size(results.P, 1)
%     fprintf('%d\t%.4f\t\t%.4f\n', i, results.P(i), results.Q(i));
% end

% 显示节点功率
% fprintf('\n节点功率：\n');
% fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
% for i = 1:size(results.p_j, 1)
%     fprintf('%d\t%.4f\t\t%.4f\n', i, results.p_j(i), results.q_j(i));
% end

% 显示发电机出力
% fprintf('\n发电机出力：\n');
% fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
% for i = 1:size(results.Pg, 1)
%     fprintf('%d\t%.4f\t\t%.4f\n', mpc.gen(i, 1), results.Pg(i), results.Qg(i));
% end

% 显示光伏出力
% if ~isempty(results.Ps)
%     fprintf('\n光伏出力：\n');
%     fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
%     for i = 1:length(results.Ps)
%         fprintf('%d\t%.4f\t\t%.4f\n', mpc.solar(i, 1), results.Ps(i));
%     end
% end

% 显示风电出力
% if ~isempty(results.Pw)
%     fprintf('\n风电出力：\n');
%     fprintf('节点\t有功(p.u.)\t无功(p.u.)\n');
%     for i = 1:length(results.Pw)
%         fprintf('%d\t%.4f\t\t%.4f\n', mpc.wind(i, 1), results.Pw(i));
%     end
% end

% 显示支路电流
% fprintf('\n支路电流：\n');
% fprintf('从节点\t到节点\t电流(p.u.)\n');
% for i = 1:length(results.l)
%     fprintf('%d\t%d\t%.4f\n', mpc.branch(i, 1), mpc.branch(i, 2), sqrt(results.l(i)));
% end

end 