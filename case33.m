% case.m - 自定义案例文件

% 母线数据
% [bus_num type V_mag V_angle V_max V_min]
case_mpc.bus = [
    1 3 1.0 0 1 1;
    2 1 1.0 0 1.05 0.95;
    3 1 1.0 0 1.05 0.95;
    4 1 1.0 0 1.05 0.95;
    5 1 1.0 0 1.05 0.95;
    6 1 1.0 0 1.05 0.95;
    7 1 1.0 0 1.05 0.95;
    8 1 1.0 0 1.05 0.95;
    9 1 1.0 0 1.05 0.95;
    10 1 1.0 0 1.05 0.95;
    11 1 1.0 0 1.05 0.95;
    12 1 1.0 0 1.05 0.95;
    13 1 1.0 0 1.05 0.95;
    14 1 1.0 0 1.05 0.95;
    15 1 1.0 0 1.05 0.95;
    16 1 1.0 0 1.05 0.95;
    17 1 1.0 0 1.05 0.95;
    18 1 1.0 0 1.05 0.95;
    19 1 1.0 0 1.05 0.95;
    20 1 1.0 0 1.05 0.95;
    21 1 1.0 0 1.05 0.95;
    22 1 1.0 0 1.05 0.95;
    23 1 1.0 0 1.05 0.95;
    24 1 1.0 0 1.05 0.95;
    25 1 1.0 0 1.05 0.95;
    26 1 1.0 0 1.05 0.95;
    27 1 1.0 0 1.05 0.95;
    28 1 1.0 0 1.05 0.95;
    29 1 1.0 0 1.05 0.95;
    30 1 1.0 0 1.05 0.95;
    31 1 1.0 0 1.05 0.95;
    32 1 1.0 0 1.05 0.95;
    33 1 1.0 0 1.05 0.95;
];

% 支路数据
% [from_bus to_bus r x b S_max I_max]
case_mpc.branch = [
    1 2 0.0922 0.0470 0 6 10;
    2 3 0.4930 0.2511 0 6 10;
    3 4 0.3660 0.1864 0 6 10;
    4 5 0.3811 0.1941 0 6 10;
    5 6 0.8190 0.7070 0 6 10;
    6 7 0.1872 0.6188 0 4.5 10;
    7 8 0.7114 0.2351 0 4.5 10;
    8 9 1.0300 0.7400 0 4.5 10;
    9 10 1.0440 0.7400 0 4.5 10;
    10 11 0.1966 0.0650 0 4.5 10;
    11 12 0.3744 0.1238 0 4.5 10;
    12 13 1.4680 1.1550 0 4.5 10;
    13 14 0.5416 0.7129 0 4.5 10;
    14 15 0.5910 0.5260 0 4.5 10;
    15 16 0.7463 0.5450 0 4.5 10;
    16 17 1.2890 1.7210 0 4.5 10;
    17 18 0.7320 0.5740 0 4.5 10;
    2 19 0.1640 0.1565 0 4.5 10;
    19 20 1.5042 1.3554 0 4.5 10;
    20 21 0.4095 0.4784 0 4.5 10;
    21 22 0.7089 0.9373 0 4.5 10;
    3 23 0.4512 0.3083 0 4.5 10;
    23 24 0.8980 0.7091 0 4.5 10;
    24 25 0.8960 0.7011 0 4.5 10;
    6 26 0.2030 0.1034 0 4.5 10;
    26 27 0.2842 0.1447 0 4.5 10;
    27 28 1.0590 0.9337 0 4.5 10;
    28 29 0.8042 0.7006 0 4.5 10;
    29 30 0.5075 0.2585 0 4.5 10;
    30 31 0.9744 0.9630 0 4.5 10;
    31 32 0.3105 0.3619 0 4.5 10;
    32 33 0.3410 0.5302 0 4.5 10;
];

% 发电机数据
% [conn_bus Pmax Pmin Qmax Qmin S k a b c]
case_mpc.gen = [
    4 1 0 1 0 1.3 0 0.1 0.1 0.1;
];

% 光伏发电数据
% [conn_bus P_max P_min n S k a b]
case_mpc.solar = [
    3 1.5 0 1 1.5 0.0872 10800 0.05;
    18 1.5 0 1 1.5 0.0872 10800 0.05;
    24 1.5 0 1 1.5 0.0872 10800 0.05;
];

% 风力发电数据
% [conn_bus P_max P_min n S k a b]
case_mpc.wind = [
    7 1 0 1 1 0.0872 11520 0.32;
    13 1 0 1 1 0.0872 11520 0.32;
    30 1 0 1 1 0.0872 11520 0.32;
];

% 储能电站数据
% [conn_bus P_max P_min n S a b c]
case_mpc.storage = [
    6 0.2 0 1 0.8 0 0 0;
];

% 母线有功需求时段数据
power_system = [
    1, 3, 0, 0, 3; ...
    2, 1, 100, 60, 3; ...
    3, 1, 90, 40, 3; ...
    4, 1, 120, 80, 3; ...
    5, 1, 60, 30, 3; ...
    6, 1, 60, 20, 3; ...
    7, 1, 200, 100, 3; ...
    8, 1, 200, 100, 3; ...
    9, 1, 60, 20, 3; ...
    10, 1, 60, 20, 3; ...
    11, 1, 45, 30, 3; ...
    12, 1, 60, 35, 3; ...
    13, 1, 60, 35, 2; ...
    14, 1, 120, 80, 2; ...
    15, 1, 60, 10, 2; ...
    16, 1, 60, 20, 2; ...
    17, 1, 60, 20, 2; ...
    18, 1, 90, 40, 2; ...
    19, 1, 90, 40, 2; ...
    20, 1, 90, 40, 2; ...
    21, 1, 90, 40, 2; ...
    22, 1, 90, 40, 2; ...
    23, 1, 90, 50, 2; ...
    24, 1, 420, 200, 1; ...
    25, 1, 420, 200, 1; ...
    26, 1, 60, 25, 1; ...
    27, 1, 60, 25, 1; ...
    28, 1, 60, 20, 1; ...
    29, 1, 120, 70, 1; ...
    30, 1, 200, 600, 1; ...
    31, 1, 150, 70, 1; ...
    32, 1, 210, 100, 1; ...
    33, 1, 60, 40, 1; ...
];
case_mpc.pd_time = power_system(:, 3) .* ones(33, 24) / 100000;

% 母线无功需求时段数据
case_mpc.qd_time = power_system(:, 4) .* ones(33, 24) / 100000;

% 电价数据
case_mpc.price = [
    0.3344 0.3344 0.3344 0.3344 0.3344 0.3344 0.3344 0.5636 0.64 0.64 0.64 0.64 0.64 0.64 0.937975 1.0373 1.0373 1.0373 1.0373 1.0373 1.0373 1.0373 0.64 0.3344;
]';
% case_mpc.price = [0.663];

% 光伏日出力时段数据
case_mpc.solar_time = [
    0 0 0 0 0 0 0 0 0.0113 0.021 0.0408 0.1794 0.2372 0.2399 0.2165 0.162 0.0837 0.0058 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0.0113 0.021 0.0408 0.1794 0.2372 0.2399 0.2165 0.162 0.0837 0.0058 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0.0113 0.021 0.0408 0.1794 0.2372 0.2399 0.2165 0.162 0.0837 0.0058 0 0 0 0 0 0;
];

% 风力日出力时段数据
case_mpc.wind_time = [
    0.1318 0.1092 0.044 0.0428 0.0318 0 0.053 0.0117 0 0 0 0 0.0379 0.1 0.1 0.1 0.1 0.0919 0.0889 0.1 0.1 0.1 0.0437 0.0376;
    0.1318 0.1092 0.044 0.0428 0.0318 0 0.053 0.0117 0 0 0 0 0.0379 0.1 0.1 0.1 0.1 0.0919 0.0889 0.1 0.1 0.1 0.0437 0.0376;
    0.1318 0.1092 0.044 0.0428 0.0318 0 0.053 0.0117 0 0 0 0 0.0379 0.1 0.1 0.1 0.1 0.0919 0.0889 0.1 0.1 0.1 0.0437 0.0376;
];