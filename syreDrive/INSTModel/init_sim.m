warning off;
InverterModel = 'Switching';    
%InverterModel = 'Average';     

load motorModel;

% S-fun Parameters
Tstep = 2e-6;
Ts    = 1/motorModel.SyreDrive.Converter.fPWM;


%% ----------------Machine and Converter  Parameters------------------------%
VDC     = motorModel.data.Vdc;
Rs      = motorModel.data.Rs;
p       = motorModel.data.p;
J       = motorModel.data.J;
Rfe     = 1e5;
accel   = 5000; % rpm/s
Bm      = 0;                     % damping constant (Nm/(rad/sec))
Tf      = 0;                 % friction loss (Nm)
Tv      = 0;%P0/(nmax*pi/30)^3;     % ventilation loss coefficient (W/(rad/s)^3 = Nm/(rad/s)^2)

MTPA    = motorModel.controlTrajectories.MTPA;
i0      = motorModel.data.i0;

id_MTPA = interp1(abs(MTPA.id+1i*MTPA.iq),MTPA.id,i0);
iq_MTPA = interp1(abs(MTPA.id+1i*MTPA.iq),MTPA.iq,i0);
Ld_inic = interp2(motorModel.IncInductanceMap_dq.Id,motorModel.IncInductanceMap_dq.Iq,motorModel.IncInductanceMap_dq.Ldd,id_MTPA,iq_MTPA);
Lq_inic = interp2(motorModel.IncInductanceMap_dq.Id,motorModel.IncInductanceMap_dq.Iq,motorModel.IncInductanceMap_dq.Lqq,id_MTPA,iq_MTPA);

T0(~isnan(motorModel.data.T0)) = motorModel.data.T0;
T0(isempty(T0)) = interp1(abs(MTPA.id+1i*MTPA.iq),MTPA.T,i0);
n0(~isnan(motorModel.data.n0)) = motorModel.data.n0;
n0(isempty(n0)) = 1000;
clear MTPA

% Converter
V0 = motorModel.SyreDrive.Converter.V0;             % power semiconductors ON treshold [V]
Rd = motorModel.SyreDrive.Converter.Rd;             % power semiconductors incremental resistance [Ohm]
dT = motorModel.SyreDrive.Converter.dT * 1e-6;      % dead time [s]
      
%% ----------------PM Initialization and Convention------------------------%
Fd0 = interp2(motorModel.FluxMap_dq.Id,motorModel.FluxMap_dq.Iq,motorModel.FluxMap_dq.Fd,0,0);
Fq0 = interp2(motorModel.FluxMap_dq.Id,motorModel.FluxMap_dq.Iq,motorModel.FluxMap_dq.Fq,0,0);
th0 = 0; %initial mechanical angle
F0_alpha = Fd0*cos(th0) - Fq0*sin(th0);
F0_beta  = Fd0*sin(th0) + Fq0*cos(th0);

if strcmp(motorModel.data.axisType,'SR') && strcmp(motorModel.data.motorType,'SR')
    Quad_Maps = 0; %SyR Convention - 1st quadrant maps
elseif strcmp(motorModel.data.axisType,'SR') && strcmp(motorModel.data.motorType,'PM')
    Quad_Maps = 1; %PM-SyR - 1st and 4th quadrant maps
elseif strcmp(motorModel.data.axisType,'PM') && strcmp(motorModel.data.motorType,'PM')
    Quad_Maps = 2; %IPM - 1st and 2st quadrant maps
end


%% ---------------Magnet Flux Estimation----------------------------%

Idd=motorModel.FluxMap_dq.Id;
Iqq=motorModel.FluxMap_dq.Iq;
Fdd=motorModel.FluxMap_dq.Fd;
Fqq=motorModel.FluxMap_dq.Fq;

if(Quad_Maps == 0)      %Syr
    Fm = 0;
elseif (Quad_Maps == 1) %PM-Syr
    Fm = abs(interp2(Idd,Iqq,Fqq,0,0));
elseif (Quad_Maps == 2) %IPM
    Fm = interp2(Idd,Iqq,Fdd,0,0);
end

clear Idd Iqq Fdd Fqq

switch(Quad_Maps)
    case 0
        InitIntg_d = 0.0;
        InitIntg_q = 0.0;
    case 1
        InitIntg_d = Fm*sin(th0);
        InitIntg_q = -Fm*cos(th0);
    case 2
        InitIntg_d = Fm*cos(th0);
        InitIntg_q = Fm*sin(th0);
end


%% ----------------dqt Inverse Flux Maps ------------------------%

% dq or dqt model
switch motorModel.SyreDrive.FMapsModel
    case 'dq Model'
        FMapsModel = 1;
        
        Fd_v = unique(motorModel.FluxMapInv_dq.Fd);
        Fq_v = unique(motorModel.FluxMapInv_dq.Fq);
        
    case 'dqt Model'
        FMapsModel = -1;

        Fd_max = max(motorModel.FluxMapInv_dqt.dataF.Fd,[],'all');
        Fq_max = max(motorModel.FluxMapInv_dqt.dataF.Fq,[],'all');
        Fd_min = min(motorModel.FluxMapInv_dqt.dataF.Fd,[],'all');
        Fq_min = min(motorModel.FluxMapInv_dqt.dataF.Fq,[],'all');
        th_min = min(motorModel.FluxMapInv_dqt.dataF.th,[],'all');
        th_max = max(motorModel.FluxMapInv_dqt.dataF.th,[],'all');
        th_dqt = motorModel.FluxMapInv_dqt.dataF.th;

        Fd_v=linspace(Fd_min,Fd_max,256);
        Fq_v=linspace(Fq_min,Fq_max,256);
        th_v=linspace(min(th_dqt,[],'all'),max(th_dqt,[],'all'),256);
        [Fd_dqt,Fq_dqt,th_dqt]=meshgrid(Fd_v,Fq_v,th_v);

        Id_dqt=interpn(motorModel.FluxMapInv_dqt.dataF.Fd,motorModel.FluxMapInv_dqt.dataF.Fq,motorModel.FluxMapInv_dqt.dataF.th,motorModel.FluxMapInv_dqt.dataF.Id,Fd_dqt,Fq_dqt,th_dqt,'cubic');
        Iq_dqt=interpn(motorModel.FluxMapInv_dqt.dataF.Fd,motorModel.FluxMapInv_dqt.dataF.Fq,motorModel.FluxMapInv_dqt.dataF.th,motorModel.FluxMapInv_dqt.dataF.Iq,Fd_dqt,Fq_dqt,th_dqt,'cubic');
        T_dqt=interpn(motorModel.FluxMapInv_dqt.dataF.Fd,motorModel.FluxMapInv_dqt.dataF.Fq,motorModel.FluxMapInv_dqt.dataF.th,motorModel.FluxMapInv_dqt.dataF.T,Fd_dqt,Fq_dqt,th_dqt,'cubic');
end


%------------------dq Inverse Flux Maps------------------------%

Fd     = motorModel.FluxMapInv_dq.Fd;
Fq     = motorModel.FluxMapInv_dq.Fq;
Id     = motorModel.FluxMapInv_dq.Id;
Iq     = motorModel.FluxMapInv_dq.Iq;
T      = motorModel.FluxMapInv_dq.T;


%% -----------------Iron Loss Model-------------------------------%%

switch motorModel.SyreDrive.IronLoss
    case 'No'
        IronLoss = 0;
    case 'Yes'
        IronLoss = 1;
        Pfe_h = motorModel.IronPMLossMap_dq.Pfes_h + motorModel.IronPMLossMap_dq.Pfer_h;
        Pfe_c = motorModel.IronPMLossMap_dq.Pfes_c + motorModel.IronPMLossMap_dq.Pfer_c;
        Ppm   = motorModel.IronPMLossMap_dq.Ppm;
        n0    = motorModel.IronPMLossMap_dq.n0;
        expH  = motorModel.IronPMLossMap_dq.expH;
        expC  = motorModel.IronPMLossMap_dq.expC;
        expPM = motorModel.IronPMLossMap_dq.expPM;

        Id_fe = motorModel.IronPMLossMap_dq.Id;
        Iq_fe = motorModel.IronPMLossMap_dq.Iq;
end  


%% --------------------User Settings-------------------------%

% Ctrl settings
switch motorModel.SyreDrive.Ctrl_type
    case 'Current control'
        Ctrl_type = 0;
    case 'Torque control'
        Ctrl_type = 2;
    case 'Speed control'
        Ctrl_type = 3;
end

% Ctrl Strategy 
switch motorModel.SyreDrive.Ctrl_strategy
    case 'FOC'
        Ctrl_strategy = 0;
    case 'DFVC'
        Ctrl_strategy = 1;
end


% Sensorless on or off
switch motorModel.SyreDrive.SS_on
    case 'Off'
        SS_on = 0;
    case 'On'
        SS_on = 1;
end

% Injected waveform
switch motorModel.SyreDrive.SS_settings.inj_waveform
    case 'Sinusoidal'
        inj_waveform = 0;
    case 'Squarewave'
        inj_waveform = 1;
end 

% Demodulation technique
switch motorModel.SyreDrive.SS_settings.dem
    case 'Current'
        dem = 0;
    case 'Flux'
        dem = 1;
end

% High speed position error estimation technique
switch motorModel.SyreDrive.SS_settings.HS_ctrl
    case 'Active Flux'
        HS_ctrl = 0;
    case 'APP'
        HS_ctrl = 1;
end


 %% coordinate transformations
%3-ph to 2-ph
Clarke = 2/3*[1 -0.5 -0.5;0 sqrt(3)/2 -sqrt(3)/2];
%2-ph to 3-ph
Clarke_inv = [1 0;-0.5 sqrt(3)/2;-0.5 -sqrt(3)/2];
%% Inverter model

Slx_name = [motorModel.data.motorName '_ctrl_INST'];

set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'diode_Vf','0.8');
set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'diode_Ron','1e-4');
set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'diode_Goff','1e-5');

switch(InverterModel)
    
    case 'Switching'
        InvModel = 1;
        set_param([Slx_name '/Inverter Model/Solver Configuration'],'UseLocalSolver','off');
        set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'device_type','ee.enum.converters.switchingdevice.ideal');
        set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'Ron','Rd');
        set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'Goff','1e-4');
        set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'Vth','0.001');
        
    case 'Average'
        InvModel = 0;
        set_param([Slx_name '/Inverter Model/Solver Configuration'],'UseLocalSolver','on');
        set_param([Slx_name '/Inverter Model/Solver Configuration'],'LocalSolverSampleTime','Ts/10');
        set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'device_type','ee.enum.converters.switchingdevice.averaged');
        set_param([Slx_name '/Inverter Model/Converter (Three-Phase)'],'Ron','Rd');
end
