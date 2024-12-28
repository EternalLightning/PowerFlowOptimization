function mpc = network_data(conf)
% NETWORK_DATA 定义示例配网数据
% 输入：
%   conf - 配置参数结构体
% 返回：
%   mpc - 包含网络数据的结构体

mpc = data_format();

if isempty(conf.network.case_file)
    error('未指定自定义案例文件路径');
end

load(conf.network.case_file, case_mpc);


% 母线数据
% [bus_num type Pd Qd V_mag V_angle V_max V_min]
% type: 1-PQ，2-PV，3-ref
if isfield(case_mpc, 'bus')
    mpc.bus = case_mpc.bus;
else
    error('总线数组(case_mpc.bus)未定义，请在案例文件中定义！')
end


% 支路数据
% [from_bus to_bus r x b S_max I_max]
if isfield(case_mpc, 'branch')
    mpc.branch = case_mpc.branch;
else
    error('支路数组(case_mpc.branch)未定义，请在案例文件中定义！')
end


% 发电机数据
% [conn_bus Pmax Pmin Qmax Qmin S a b c]
if isfield(case_mpc, 'gen')
    mpc.gen = case_mpc.gen;
else
    error('发电机数组(case_mpc.gen)未定义，请在案例文件中定义！')
end


% 光伏发电数据
% [conn_bus P_max P_min Q_max Q_min S k]
if isfield(case_mpc, 'solar')
    mpc.solar = case_mpc.solar;
    if ~isfield(case_mpc, 'solar_time')
        mpc.solar_time = 0.35 * ones(size(mpc.solar, 1), conf.time);
        disp('在案例文件中找到光伏数组，但日出力数组(case_mpc.solar_time)未定义，默认为最大出力的35%！')
    elseif size(mpc.solar_time, 1) ~= size(case_mpc.solar_time, 1)
        error(['光伏电站数量(', size(mpc.solar, 1), ...
               ')与给定时段数量(', size(case_mpc.solar_time, 1), ')不匹配！'])
    elseif size(case_mpc.solar_time, 2) ~= conf.time
        error(['光伏日出力时段跨度(', size(case_mpc.solar_time, 2), ...
               ')与设置(', conf.time, ')不匹配！'])
    else
        mpc.solar_time = case_mpc.solar_time;
    end
else
    disp('光伏数组(case_mpc.solar)未定义，默认为空！')
end


% 储存电站数据
% [conn_bus P_max P_min Q_max Q_min S u k]
if isfield(case_mpc, 'storage')
    mpc.storage = case_mpc.storage;
else
    disp('储存电站数组(case_mpc.storage)未定义，默认为空！')
end


if isfield(case_mpc, 'pd_time')
    if size(case_mpc.pd_time, 2) ~= conf.time
        error(['发电机日出力时段跨度(', size(case_mpc.pd_time, 2), ...
               ')与设置(', conf.time, ')不匹配！'])
    elseif size(case_mpc.pd_time, 1) ~= size(mpc.gen, 1)
        error(['发电机数量(', size(mpc.gen, 1), ...
               ')与给定时段数量(', size(case_mpc.pd_time, 1), ')不匹配！'])
    else
        mpc.pd_time = case_mpc.pd_time;
    end
else
    mpc.pd_time = ones(size(mpc.gen, 1), conf.time);
end


if isfield(case_mpc, 'qd_time')
    if size(case_mpc.qd_time, 2) ~= conf.time
        error(['发电机日出力时段跨度(', size(case_mpc.qd_time, 2), ...
               ')与设置(', conf.time, ')不匹配！'])
    elseif size(case_mpc.qd_time, 1) ~= size(mpc.gen, 1)
        error(['发电机数量(', size(mpc.gen, 1), ...
               ')与给定时段数量(', size(case_mpc.qd_time, 1), ')不匹配！'])
    else
        mpc.qd_time = case_mpc.qd_time;
    end
else
    mpc.qd_time = ones(size(mpc.gen, 1), conf.time);
end


% 根据配置选择拓扑结构
switch conf.network.topology
    case 'ieee33'
        mpc.topology = mpc.built_in.ieee33;
    case 'ieee123'
        mpc.topology = mpc.built_in.ieee123;
    case 'custom'
        if ~isfield(case_mpc, 'topology')
            error("配置文件中，拓扑选择为'custom'，但案例文件中未自定义拓扑结构！");
        end
        mpc.topology = case_mpc.topology;
    otherwise
        error('不支持的网络拓扑类型，请修改配置文件！');
end

% 风电数据
% [bus capacity factor Qmax Qmin cost]
% mpc.wind = case_mpc.wind;

end 