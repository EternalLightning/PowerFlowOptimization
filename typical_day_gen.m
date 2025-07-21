function [num_clusters, prob, pv_time] = typical_day_gen(xlsx_path)

% 读取 Excel 文件
data = readtable(xlsx_path);

n = size(data, 1) / 24;
X = zeros(n, 24);

for i = 1:n
    X(i, :) = data.GlobalHorizontalIrradiance_GHI_W_m2((24 * (i - 1) + 1):(24 * i))';
end

fuzziness = 2;    % 模糊因子
max_iter = 100;   % 最大迭代次数
error = 1e-5;     % 收敛误差
eval = zeros(4, 1);

for num_clusters = 2:sqrt(n)  % 设置聚类中心个数
    [centers, U, obj_fcn] = fcm(X, num_clusters, [fuzziness, max_iter, error]);
    [maxU, index] = max(U);
    eval(num_clusters - 1) = evalclusters(X, index','DaviesBouldin').CriterionValues;
end

num_clusters = find(eval == min(eval)) + 1;

fprintf('当分类数量为 %d 个时效果最佳！', num_clusters);

[centers, U, obj_fcn] = fcm(X, num_clusters, [fuzziness, max_iter, error]);
[maxU, index] = max(U);

tmp = tabulate(index);
prob = tmp(:, 3) / 100;  % 场景概率
pv_time = centers;

end