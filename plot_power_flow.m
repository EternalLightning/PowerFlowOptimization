function plot_power_flow(results, mpc)
% PLOT_POWER_FLOW 绘制功率分布图
% 输入：
%   results - 优化结果结构体
%   mpc - 包含网络数据的结构体

% 创建新图窗
figure('Name', '节点功率分布');

% 准备数据
nb = size(mpc.bus, 1);
P_gen = zeros(nb, 1);
P_solar = zeros(nb, 1);
P_wind = zeros(nb, 1);
P_load = mpc.bus(:, 3);

% 统计各类型发电功率
for i = 1:size(mpc.gen, 1)
    P_gen(mpc.gen(i, 1)) = results.Pg(i);
end

for i = 1:size(mpc.solar, 1)
    P_solar(mpc.solar(i, 1)) = results.Ps(i);
end

for i = 1:size(mpc.wind, 1)
    P_wind(mpc.wind(i, 1)) = results.Pw(i);
end

% 创建堆叠柱状图
bar_data = [P_gen, P_solar, P_wind, -P_load];
b = bar(bar_data, 'stacked');

% 设置颜色
b(1).FaceColor = [0.2 0.6 1.0];     % 传统发电机：蓝色
b(2).FaceColor = [1.0 0.8 0.0];     % 光伏：黄色
b(3).FaceColor = [0.0 0.8 0.4];     % 风电：绿色
b(4).FaceColor = [0.8 0.2 0.2];     % 负荷：红色

% 添加标签和标题
xlabel('节点编号');
ylabel('有功功率 (p.u.)');
title('节点功率分布');
grid on;

% 添加图例
legend('传统发电', '光伏发电', '风力发电', '负荷', 'Location', 'best');

% 计算支路功率流
figure('Name', '支路功率流');
nl = size(mpc.branch, 1);
P_flow = zeros(nl, 1);
for i = 1:nl
    branch = mpc.branch(i, :);
    fbus = branch(1);
    tbus = branch(2);
    r = branch(3);
    x = branch(4);
    z2 = r ^ 2 + x ^ 2;
    P_flow(i) = (results.v(fbus) - results.v(tbus)) * r / z2;
end

% 绘制支路功率流
bar(P_flow);
xlabel('支路编号');
ylabel('有功功率流 (p.u.)');
title('支路功率流分布');
grid on;

end 