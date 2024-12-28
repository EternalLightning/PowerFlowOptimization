function plot_voltage_profile(results, mpc)
% PLOT_VOLTAGE_PROFILE 绘制电压分布图
% 输入：
%   results - 优化结果结构体
%   mpc - 包含网络数据的结构体

figure('Name', '节点电压分布');
bar(results.v);
hold on;
plot(get(gca, 'xlim'), [mpc.bus(1,7) mpc.bus(1,7)], 'r--', 'LineWidth', 1.5);
plot(get(gca, 'xlim'), [mpc.bus(1,8) mpc.bus(1,8)], 'r--', 'LineWidth', 1.5);
hold off;

xlabel('节点编号');
ylabel('电压幅值 (p.u.)');
title('节点电压分布');
grid on;

% 添加图例
legend('节点电压', '电压下限', '电压上限', 'Location', 'best');

% 设置坐标轴范围
ylim([min(mpc.bus(:,7))*0.95 max(mpc.bus(:,8))*1.05]);

end 