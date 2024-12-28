% 2022-10-06 XXY
% Distribution System Volt/Var Optimization

% Distribution Network Model: SOCP
% Control device: OLTC and capacitor 
% Method: Optimal power flow

% Tips: The variables starting with 'par_' represent parameters, and those 
% starting with 'var_' represent decision variables of optimization problems. 

clear

%% Data
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, ...
    RATE_C, TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[BUS_OLTC, KMIN, KMAX, MAXTAP_OLTC] = idx_oltc;
[BUS_CAP, BASE_CAP, MAX_CAPNUM] = idx_cap;
[BUS_PV,FORECASTP_PV,FORECASTQ_PV, CAPACITY_PV, PF_PV, ...
  DETPMIN_PV, DETPMAX_PV ,DETPMEAN_PV,DETPSIGMA_PV] = idx_pv;

[baseMVA, Bus, Branch, Oltc, Cap, Pv, Gen] = case33;

%% define parameter 
Nl = size(Branch,1);
Nb = size(Bus,1);
Ncap = size(Cap,1);
Npv = size(Pv,1);
Nbe = ceil(log2(Oltc(1,MAXTAP_OLTC)));

%% define variable
var_U2 = sdpvar(Nb,1); % square of voltage magnitude
var_L2 = sdpvar(Nl,1); % square of current
var_Pf = sdpvar(Nl,1); % Pij
var_Qf = sdpvar(Nl,1); % Qij
var_Cap = intvar(Ncap,1); % position of capacitor banks, interger variables
var_pvp = sdpvar(Npv,1);  % cutailed active power of PV units
var_oltc_k = sdpvar(1);    % ratio of OLTC 
var_oltc_t = intvar(1);    % tap position of OLTC
var_oltc_BE = binvar(Nbe,1); % binary variables OLTC
var_oltc_u =  sdpvar(1);     % intermediate variale of OLTC
var_oltc_aux = sdpvar(Nbe,1); % auxiliary variable of the big-M method of OLTC

%% Matrices for mapping line flow, power of capcitors and PV units to nodal power 
matrix_fbus = sparse(Branch(:,F_BUS),(1:Nl)',ones(Nl,1),Nb,Nl); 
matrix_tbus = sparse(Branch(:,T_BUS),(1:Nl)',ones(Nl,1),Nb,Nl);
matrix_cap = sparse(Cap(:,BUS_CAP),(1:Ncap)',ones(Ncap,1),Nb,Ncap);
matrix_pv = sparse(Pv(:,BUS_PV),(1:Npv)',ones(Npv,1),Nb,Npv);
matrix_fbus2 = matrix_fbus(2:end,:); % 不考虑节点1的注入功率平衡约束
matrix_tbus2 = matrix_tbus(2:end,:); % 不考虑节点1的注入功率平衡约束地方

%% constraints
cons = [];
% Distflow SOCP 
% Reference: Hierarchical Central-Local Inverter-based Voltage Control in Distribution 
% Networks Considering Stochastic PV Power Admissible Range, Eq: (3-2)-(3-5)
temp = [zeros(Nb-1,1) eye(Nb-1)];
cons = [cons, matrix_fbus2 * var_Pf == matrix_tbus2 * (var_Pf - Branch(:,BR_R).* var_L2) ...
    + temp * (matrix_pv * (Pv(:,FORECASTP_PV) - var_pvp)/baseMVA - Bus(:,PD)/baseMVA)];
cons = [cons, matrix_fbus2 * var_Qf == matrix_tbus2 * (var_Qf - Branch(:,BR_X) .* var_L2) ...
    + temp * (matrix_cap * (Cap(:,BASE_CAP).* var_Cap)/baseMVA - Bus(:,QD)/baseMVA)];
cons = [cons, matrix_tbus' * var_U2 == matrix_fbus' * var_U2  ...
    - 2*(Branch(:,BR_R).* var_Pf + Branch(:,BR_X).* var_Qf) + (Branch(:,BR_R).^2 + Branch(:,BR_X).^2).* var_L2];
cons = [cons, var_Pf.^2 + var_Qf.^2 <= var_L2.* (matrix_fbus'*var_U2)];

% Capacitor banks
cons = [cons, 0 <= var_Cap <= Cap(:,MAX_CAPNUM)];
% Squared voltage magnitude 
cons = [cons, Bus(:,VMIN).^2 <= var_U2 <= Bus(:,VMAX).^2];
% Squared current 
cons = [cons, var_L2 >= 0];
% curtailed active power of PV units
cons = [cons, 0 <= var_pvp <= Pv(:,FORECASTP_PV)];
% OLTC 
% Reference: Data-driven Stochastic Programming for Energy Storage System Planning 
% in High PV-penetrated Distribution Network, Equations (7)-(11)
par_Us = 1;  % var_U2(1) = par_Us * var_oltc_k^2;
par_detk = (Oltc(KMAX) - Oltc(KMIN)) / Oltc(MAXTAP_OLTC);
par_BE = (2.^[0:Nbe-1])';
par_bM = 10^6;
cons = [cons, var_oltc_k == Oltc(KMIN) + var_oltc_t * par_detk];
cons = [cons, 0 <= var_oltc_t <= Oltc(MAXTAP_OLTC)];
cons = [cons, var_oltc_t == par_BE'* var_oltc_BE];
cons = [cons, var_oltc_u == par_Us * (Oltc(KMIN) + par_detk * var_oltc_t) ]; % var_oltc_u=par_Us*var_oltc_k
cons = [cons, var_U2(1) == Oltc(KMIN) * var_oltc_u + par_detk *(par_BE'* var_oltc_aux) ];
cons = [cons, 0 <= repmat(var_oltc_u, Nbe, 1) - var_oltc_aux <= par_bM * (1 - var_oltc_BE)];
cons = [cons, 0 <= var_oltc_aux <= par_bM * var_oltc_BE];

%% objective function
obj = var_Pf(1); 

%% solve
options = sdpsettings;
% options.cplex.MIPGap=0.001;
options.solver = 'cplex';
sol = optimize(cons,obj,options);

%% check the results 
rU = sqrt(value(var_U2));
rL2 = value(var_L2);
rpf = value(var_Pf);
rqf = value(var_Qf);
rcap = value(var_Cap);
roltck = value(var_oltc_k); 
roltct = value(var_oltc_t);
rpvp = value(var_pvp);
rerror_socp = value(var_Pf.^2 + var_Qf.^2 - (var_L2 .* (matrix_fbus'*var_U2)));