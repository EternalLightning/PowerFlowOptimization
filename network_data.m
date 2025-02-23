function mpc = network_data(conf)
% NETWORK_DATA 定义示例配网数据
% 输入：
%   conf - 配置参数结构体
% 返回：
%   mpc - 包含网络数据的结构体

mpc = data_format(conf);

if isempty(conf.network.case_file)
    error('未指定自定义案例文件路径');
end

run(conf.network.case_file);


% 母线数据
% [bus_num type V_mag V_angle V_max V_min]
% type: 1-PQ，2-PV，3-ref
if ~isfield(case_mpc, 'bus')
    error('母线数组(case_mpc.bus)未定义，请在案例文件中定义！');
elseif size(case_mpc.bus, 2) ~= 6
    error('母线数组维数错误(%d)，请检查！', size(case_mpc.bus, 2));
else
    mpc.bus = case_mpc.bus;
end


% 支路数据
% [from_bus to_bus r x b S_max I_max]
if ~isfield(case_mpc, 'branch')
    error('支路数组(case_mpc.branch)未定义，请在案例文件中定义！');
elseif size(case_mpc.branch, 2) ~= 7
    error('支路数组维数错误(%d)，请检查！', size(case_mpc.branch, 2));
else
    mpc.branch = case_mpc.branch;
end


% 发电机数据
% [conn_bus Pmax Pmin Qmax Qmin S a b c]
if ~isfield(case_mpc, 'gen')
    error('发电机数组(case_mpc.gen)未定义，请在案例文件中定义！');
elseif size(case_mpc.gen, 2) ~= 10
    error('发电机数组维数错误(%d)，请检查！', size(case_mpc.gen, 2));
else
    mpc.gen = [case_mpc.gen; 1 1000 -1000 1000 -1000 2000 0 0 0 0];
end


% 光伏发电数据
% [conn_bus P_max P_min n S k a b]
if isfield(case_mpc, 'solar')
    if size(case_mpc.solar, 2) ~= 8
        error('光伏数组维数错误(%d)，请检查！', size(case_mpc.solar, 2));
    end
    mpc.solar = case_mpc.solar;
    if ~isfield(case_mpc, 'solar_time')
        mpc.solar_time = 0.35 * ones(size(mpc.solar, 1), conf.time);
        disp('在案例文件中找到光伏数组，但日出力数组(case_mpc.solar_time)未定义，默认为最大出力的35%！');
    elseif size(mpc.solar, 1) ~= size(case_mpc.solar_time, 1)
        error('光伏电站数量(%d)与给定时段数量(%d)不匹配！', size(mpc.solar, 1), size(case_mpc.solar_time, 1));
    elseif size(case_mpc.solar_time, 2) ~= conf.time
        error('光伏日出力时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.solar_time, 2), conf.time);
    else
        mpc.solar_time = case_mpc.solar_time;
    end
else
    disp('光伏数组(case_mpc.solar)未定义，默认为空！');
    mpc.solar = [1 0 0 1 0 0 0 0];
    mpc.solar_time = 0;
end


% 风力发电数据
% [conn_bus P_max P_min n S k a b]
if isfield(case_mpc, 'wind')
    if size(case_mpc.wind, 2) ~= 8
        error('风力数组维数错误(%d)，请检查！', size(case_mpc.wind, 2));
    end
    mpc.wind = case_mpc.wind;
    if ~isfield(case_mpc, 'wind_time')
        mpc.wind_time = 0.5 * ones(size(mpc.wind, 1), conf.time);
        disp('在案例文件中找到风力数组，但日出力数组(case_mpc.wind_time)未定义，默认为最大出力的50%！');
    elseif size(mpc.wind, 1) ~= size(case_mpc.wind_time, 1)
        error('风力发电机数量(%d)与给定时段数量(%d)不匹配！', size(mpc.wind, 1), size(case_mpc.wind_time, 1));
    elseif size(case_mpc.wind_time, 2) ~= conf.time
        error('光伏日出力时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.wind_time, 2), conf.time);
    else
        mpc.wind_time = case_mpc.wind_time;
    end
else
    disp('风力数组(case_mpc.wind)未定义，默认为空！');
    mpc.wind = [1 0 0 1 0 0 0 0];
    mpc.wind_time = 0;
end


% 储存电站数据
% [conn_bus P_max P_min n S a b c]
if ~isfield(case_mpc, 'storage')
    disp('储存电站数组(case_mpc.storage)未定义，默认为空！');
    mpc.storage = [1 0 0 1 0 0 0 0];
elseif size(case_mpc.storage, 2) ~= 8
    error('储能电站数组维数错误(%d)，请检查！', size(case_mpc.storage, 2));
else
    mpc.storage = case_mpc.storage;
end


if isfield(case_mpc, 'pd_time')
    if size(case_mpc.pd_time, 2) ~= conf.time
        error('母线有功需求时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.pd_time, 2), conf.time);
    elseif size(case_mpc.pd_time, 1) ~= size(mpc.bus, 1)
        error('母线有功需求数量(%d)与给定母线数量(%d)不匹配！', size(case_mpc.pd_time, 1), size(mpc.bus, 1));
    else
        mpc.pd_time = case_mpc.pd_time;
    end
else
    error('母线有功需求数组(case_mpc.pd_time)未定义！请在案例文件中定义！');
end


if isfield(case_mpc, 'qd_time')
    if size(case_mpc.qd_time, 2) ~= conf.time
        error('母线有功需求时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.qd_time, 2), conf.time);
    elseif size(case_mpc.qd_time, 1) ~= size(mpc.bus, 1)
        error('母线有功需求数量(%d)与给定母线数量(%d)不匹配！', size(case_mpc.qd_time, 1), size(mpc.bus, 1));
    else
        mpc.qd_time = case_mpc.qd_time;
    end
else
    error('母线无功需求数组(case_mpc.qd_time)未定义！请在案例文件中定义！');
end


% 电价数据
if ~isfield(case_mpc, 'price')
    error('电价数组(case_mpc.price)未定义，请在案例文件中定义！')
elseif size(case_mpc.price, 1) ~= conf.time
    error('电价时段跨度(%d)与设置(%d)不匹配！', size(case_mpc.price, 1), conf.time);
else
    mpc.price = case_mpc.price;
end

end