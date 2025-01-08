function [from_line, to_line] = get_connected_lines(mpc, bus_i)
% get_connected_lines 获取连接到指定节点的所有支路**索引**
% 输入：
%   mpc - 包含网络数据的结构体
%   bus_i - 目标节点编号
% 输出：
%   from_lines - 以该节点为起点的支路索引
%   to_lines - 以该节点为终点的支路索引

% 获取以该节点为起点的支路
from_line = find(mpc.branch(:, 1) == bus_i);

% 获取以该节点为终点的支路
to_line = find(mpc.branch(:, 2) == bus_i);

end 