function display_results(results, mpc, conf)
% DISPLAY_RESULTS 显示优化结果
% 输入：
%   results - 优化结果结构体
%   mpc - 包含网络数据的结构体

% 显示目标函数值
fprintf('\n优化结果：\n');
fprintf('总成本: %.2f 元\n', results.obj);
fprintf('投资成本: %.2f 元\n', results.inv_cost);
fprintf('运行成本: %.2f 元\n', results.run_cost);

if isfield(conf, 'scenarios') && conf.scenarios > 1
    fprintf('光伏安装容量: %.2f\n', results.S_pv(results.tactical_pv == 1) * conf.base.S);
    fprintf('风电安装容量: %.2f\n', results.S_wind(results.tactical_wind == 1) * conf.base.S);
    for s = 1:conf.scenarios
        fprintf('\n==== 场景 %d ====\n', s);
        % 电压
        figure('Name', ['电压幅值-场景' num2str(s)]);
        if conf.time == 24
            fprintf('节点电压幅值(p.u.)三维图\n');
            bar3(sqrt(results.v(:,:,s)));
            fprintf('节点电压幅值(p.u.)数据如下\n');
            disp(sqrt(results.v(:,:,s)));
        elseif conf.time == 1
            fprintf('节点电压幅值(p.u.)图\n');
            bar(1:size(results.v, 1), sqrt(results.v(:,1,s)));
        end

        % 支路有功功率
        figure('Name', ['支路有功功率-场景' num2str(s)]);
        if conf.time == 24
            fprintf('支路有功功率(p.u.)三维图\n');
            bar3(results.P(:,:,s));
            fprintf('支路有功功率(p.u.)数据如下\n');
            disp(results.P(:,:,s));
        elseif conf.time == 1
            fprintf('支路有功功率(p.u.)图\n');
            bar(1:size(results.P, 1), results.P(:,1,s));
        end

        % 发电机出力
        if mpc.flag.gen
            figure('Name', ['发电机有功功率-场景' num2str(s)]);
            if conf.time == 24
                fprintf('\n发电机有功功率(p.u)三维图\n');
                bar3(results.P_gen(:,:,s));
                fprintf('发电机有功功率(p.u.)数据如下\n');
                disp(results.P_gen(:,:,s));
            elseif conf.time == 1
                fprintf('发电机有功功率(p.u.)图\n');
                bar(results.P_gen(:,1,s));
            end
        end

        % 光伏出力
        if mpc.flag.pv
            if any(results.tactical_pv == 1)
                figure('Name', ['光伏有功功率-场景' num2str(s)]);
                idx = find(results.tactical_pv == 1);
                if conf.time == 24
                    fprintf('\n光伏有功功率(p.u)三维图\n');
                    bar3(results.P_pv(idx,:,s));
                    fprintf('光伏有功功率(p.u.)数据如下\n');
                    disp(results.P_pv(idx,:,s));
                elseif conf.time == 1
                    fprintf('光伏有功功率(p.u.)图\n');
                    bar(results.P_pv(idx,1,s));
                end
            else
                fprintf('计算得出安装光伏是不经济的！\n');
            end
        end

        % 风电出力
        if mpc.flag.wind
            if any(results.tactical_wind == 1)
                figure('Name', ['风电有功功率-场景' num2str(s)]);
                idx = find(results.tactical_wind == 1);
                if conf.time == 24
                    fprintf('\n风电有功功率(p.u)三维图\n');
                    bar3(results.P_wind(idx,:,s));
                    fprintf('风电有功功率(p.u.)数据如下\n');
                    disp(results.P_wind(idx,:,s));
                elseif conf.time == 1
                    fprintf('风电有功功率(p.u.)图\n');
                    bar(results.P_wind(idx,1,s));
                end
            else
                fprintf('计算得出安装风电是不经济的！\n');
            end
        end

        % 储能电站充放电功率
        if mpc.flag.ess
            if any(results.tactical_ess == 1)
                figure('Name', ['储能电站充放电功率-场景' num2str(s)]);
                idx = find(results.tactical_ess == 1);
                if conf.time == 24
                    fprintf('\n储能电站充放电功率(p.u)三维图\n');
                    bar3(results.P_ess(idx,:,s));
                    fprintf('储能电站充放电功率(p.u.)数据如下\n');
                    disp(results.P_ess(idx,:,s));
                elseif conf.time == 1
                    fprintf('储能电站充放电功率(p.u.)图\n');
                    bar(results.P_ess(idx,1,s));
                end
            else
                fprintf('计算得出安装储能电站是不经济的！\n');
            end
        end
    end
else
    % 电压
    figure('Name', '电压幅值');
    if conf.time == 24
        fprintf('节点电压幅值(p.u.)三维图\n');
        bar3(sqrt(results.v));
        fprintf('节点电压幅值(p.u.)数据如下\n');
        disp(sqrt(results.v));
    elseif conf.time == 1
        fprintf('节点电压幅值(p.u.)图\n');
        bar(1:size(results.v, 1), sqrt(results.v));
    end


    % 支路有功功率
    figure('Name', '支路有功功率');
    if conf.time == 24
        fprintf('支路有功功率(p.u.)三维图\n');
        bar3(results.P);
        fprintf('支路有功功率(p.u.)数据如下\n');
        disp(results.P);
    elseif conf.time == 1
        fprintf('支路有功功率(p.u.)图\n');
        bar(1:size(results.P, 1), results.P);
    end


    % 显示发电机出力
    if mpc.flag.gen
        figure('Name', '发电机有功功率');
        if conf.time == 24
            fprintf('\n发电机有功功率(p.u)三维图\n');
            bar3(results.P_gen);
            fprintf('发电机有功功率(p.u.)数据如下\n');
            disp(results.P_gen);
        elseif conf.time == 1
            fprintf('发电机有功功率(p.u.)图\n');
            bar(results.P_gen);
        end
    end

    % 显示光伏出力
    if mpc.flag.pv
        if any(results.tactical_pv == 1)
            % 新增：显示光伏安装容量
            fprintf('光伏安装容量: %.2f\n', sum(results.pv_capacity(results.tactical_pv == 1)));
            figure('Name', '光伏有功功率');
            if conf.time == 24
                fprintf('\n光伏有功功率(p.u)三维图\n');
                bar3(results.P_pv(results.tactical_pv == 1, :));
                fprintf('光伏有功功率(p.u.)数据如下\n');
                disp(results.P_pv(results.tactical_pv == 1, :));
            elseif conf.time == 1
                fprintf('光伏有功功率(p.u.)图\n');
                bar(results.P_pv(results.tactical_pv == 1, :));
            end
        else
            fprintf('计算得出安装光伏是不经济的！\n');
        end
    end

    % 显示风电出力
    if mpc.flag.wind
        if any(results.tactical_wind == 1)
            % 新增：显示风电安装容量
            fprintf('风电安装容量: %.2f\n', sum(results.wind_capacity(results.tactical_wind == 1)));
            figure('Name', '风电有功功率');
            if conf.time == 24
                fprintf('\n风电有功功率(p.u)三维图\n');
                bar3(results.P_wind(results.tactical_wind == 1, :));
                fprintf('风电有功功率(p.u.)数据如下\n');
                disp(results.P_wind(results.tactical_wind == 1, :));
            elseif conf.time == 1
                fprintf('风电有功功率(p.u.)图\n');
                bar(results.P_wind(results.tactical_wind == 1, :));
            end
        else
            fprintf('计算得出安装风电是不经济的！\n');
        end
    end

    % 显示储能电站充放电功率
    if mpc.flag.ess
        if any(results.tactical_ess == 1)
            figure('Name', '储能电站充放电功率');
            if conf.time == 24
                fprintf('\n储能电站充放电功率(p.u)三维图\n');
                bar3(results.P_ess(results.tactical_ess == 1, :));
                fprintf('储能电站充放电功率(p.u.)数据如下\n');
                disp(results.P_ess(results.tactical_ess == 1, :));
            elseif conf.time == 1
                fprintf('储能电站充放电功率(p.u.)图\n');
                bar(results.P_ess(results.tactical_ess == 1, :));
            end
        else
            fprintf('计算得出安装储能电站是不经济的！\n');
        end
    end
end