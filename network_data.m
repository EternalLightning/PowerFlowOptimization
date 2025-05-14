function mpc = network_data(conf)
% NETWORK_DATA 定义示例配网数据
% 输入：
%   conf - 配置参数结构体
% 返回：
%   mpc - 包含网络数据的结构体

% 定义基值
mpc.S_base = conf.base.S;    % 基准容量
mpc.U_base = conf.base.U;    % 基准电压
mpc.Z_base = mpc.U_base ^ 2 / mpc.S_base;  % 基准阻抗
mpc.I_base = mpc.S_base / (mpc.U_base * sqrt(3)); % 基准电流

mpc.flag.gen = true;
mpc.flag.pv = true;
mpc.flag.wind = true;
mpc.flag.storage = true;


if isempty(conf.network.case_file)
    error('未指定自定义案例文件路径');
end

run(conf.network.case_file);


% 母线数据
% [bus_num type V_mag V_angle V_max V_min]
% type: 1-PQ，2-PV，3-ref
if ~isfield(case_mpc, 'bus')
    error('母线矩阵(case_mpc.bus)未定义，请在案例文件中定义！');
elseif size(case_mpc.bus, 2) ~= 6
    error('母线矩阵维数错误(%d)，请检查！', size(case_mpc.bus, 2));
else
    mpc.bus = case_mpc.bus;
end


% 支路数据
% [from_bus to_bus r x b S_max I_max]
if ~isfield(case_mpc, 'branch')
    error('支路矩阵(case_mpc.branch)未定义，请在案例文件中定义！');
elseif size(case_mpc.branch, 2) ~= 7
    error('支路矩阵维数错误(%d)，请检查！', size(case_mpc.branch, 2));
else
    mpc.branch = case_mpc.branch;
    mpc.branch(:, 3:5) = case_mpc.branch(:, 3:5) / mpc.Z_base;
    % mpc.branch(:, 6) = case_mpc.branch(:, 6) / mpc.baseS;
    % mpc.branch(:, 7) = case_mpc.branch(:, 7) / mpc.baseI;
end


% 发电机数据
if ~isfield(case_mpc, 'gen')
    mpc.gen = [1 1000 -1000 1000 -1000 1414 0 0 1 1 0 1];
    mpc.flag.gen = false;
    disp('发电机矩阵(case_mpc.gen)未定义，默认为空！');
elseif size(case_mpc.gen, 2) ~= 12
    error('发电机矩阵维数错误(%d)，请检查！', size(case_mpc.gen, 2));
else
    mpc.gen = [case_mpc.gen; 1 1000 -1000 1000 -1000 1414 0 0 1 1 0 1];
end


% 光伏发电数据
% [conn_bus P_max P_min n S k a b]
if isfield(case_mpc, 'pv')
    if size(case_mpc.pv, 2) ~= 8
        error('光伏矩阵维数错误(%d)，请检查！', size(case_mpc.pv, 2));
    end
    mpc.pv = case_mpc.pv;
    % 光伏日出力时段数据
    if isfield(case_mpc, 'pv_time')
        if size(case_mpc.pv_time, 1) ~= conf.scenarios
            error('光伏日出力场景数量(%d)与配置的场景数量(%d)不匹配！', size(case_mpc.pv_time, 3), conf.scenarios);
        elseif size(case_mpc.pv_time, 2) ~= conf.time
            error('光伏日出力时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.pv_time, 2), conf.time);
        else
            mpc.pv_time = case_mpc.pv_time;
        end
    else
        error('光伏日出力矩阵(case_mpc.pv_time)未定义！请在案例文件中定义！');
    end
else
    disp('光伏矩阵(case_mpc.pv)未定义，默认为空！');
    mpc.pv = [1 0 0 1 0 0 0 0];
    mpc.pv_time = 0;
    mpc.flag.pv = false;
end


% 风力发电数据
% [conn_bus P_max P_min n S k a b]
if isfield(case_mpc, 'wind')
    if size(case_mpc.wind, 2) ~= 8
        error('风力矩阵维数错误(%d)，请检查！', size(case_mpc.wind, 2));
    end
    mpc.wind = case_mpc.wind;
    % 风力日出力时段数据
    if isfield(case_mpc, 'wind_time')
        if size(case_mpc.wind_time, 1) ~= conf.scenarios
            error('风力日出力场景数量(%d)与配置的场景数量(%d)不匹配！', size(case_mpc.wind_time, 3), conf.scenarios);
        elseif size(case_mpc.wind_time, 2) ~= conf.time
            error('风力日出力时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.wind_time, 2), conf.time);
        else
            mpc.wind_time = case_mpc.wind_time;
        end
    else
        error('风力日出力矩阵(case_mpc.wind_time)未定义！请在案例文件中定义！');
    end
else
    disp('风力矩阵(case_mpc.wind)未定义，默认为空！');
    mpc.wind = [1 0 0 1 0 0 0 0];
    mpc.wind_time = 0;
    mpc.flag.wind = false;
end


% 储存电站数据
% [conn_bus P_max P_min n S a b c]
if ~isfield(case_mpc, 'storage')
    disp('储存电站矩阵(case_mpc.storage)未定义，默认为空！');
    mpc.storage = [1 0 0 1 0 0 0 0];
    mpc.flag.storage = false;
elseif size(case_mpc.storage, 2) ~= 8
    error('储能电站矩阵维数错误(%d)，请检查！', size(case_mpc.storage, 2));
else
    mpc.storage = case_mpc.storage;
end


% 母线有功需求时段数据
if isfield(case_mpc, 'pd_time')
    if size(case_mpc.pd_time, 3) ~= conf.scenarios
        error('母线有功需求场景数量(%d)与配置的场景数量(%d)不匹配！', size(case_mpc.pd_time, 3), conf.scenarios);
    elseif size(case_mpc.pd_time, 2) ~= conf.time
        error('母线有功需求时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.pd_time, 2), conf.time);
    elseif size(case_mpc.pd_time, 1) ~= size(mpc.bus, 1)
        error('母线有功需求数量(%d)与给定母线数量(%d)不匹配！', size(case_mpc.pd_time, 1), size(mpc.bus, 1));
    else
        mpc.pd_time = case_mpc.pd_time / (mpc.S_base * 1000);
    end
else
    error('母线有功需求矩阵(case_mpc.pd_time)未定义！请在案例文件中定义！');
end


% 母线无功需求时段数据
if isfield(case_mpc, 'qd_time')
    if size(case_mpc.qd_time, 3) ~= conf.scenarios
        error('母线无功需求场景数量(%d)与配置的场景数量(%d)不匹配！', size(case_mpc.qd_time, 3), conf.scenarios);
    elseif size(case_mpc.qd_time, 2) ~= conf.time
        error('母线无功需求时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.qd_time, 2), conf.time);
    elseif size(case_mpc.qd_time, 1) ~= size(mpc.bus, 1)
        error('母线无功需求数量(%d)与给定母线数量(%d)不匹配！', size(case_mpc.qd_time, 1), size(mpc.bus, 1));
    else
        mpc.qd_time = case_mpc.qd_time / (mpc.S_base * 1000);
    end
else
    error('母线无功需求矩阵(case_mpc.qd_time)未定义！请在案例文件中定义！');
end


% 电价数据
if ~isfield(case_mpc, 'price')
    error('电价矩阵(case_mpc.price)未定义，请在案例文件中定义！')
elseif size(case_mpc.price, 1) ~= conf.time
    error('电价时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.price, 1), conf.time);
else
    mpc.price = case_mpc.price;
end

end