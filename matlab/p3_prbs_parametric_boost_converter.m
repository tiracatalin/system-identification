%%
% Nume si prenume: Tira Catalin
clear all
clearvars
clc

%% Magic numbers (replace with received numbers)
m = 5;
n = 14;

%% Process data and experiment setup (fixed, do not modify)
u_star = 0.15+n*0.045; % trapeze + PRBS amplitudes
delta = 0.02;
delta_spab = 0.015;

E = 12;  % converter source voltage

umin = 0; umax = 0.98; % input saturation
assert(u_star < umax-0.1)
ymin = 0; ymax = 1/(1-u_star)*E*2; % output saturation

% circuit components + parasitic terms
R = 15;
rL = 10e-3;
rC = 0.2;
rDS1 = 0.01;
rDS2 = 0.01;
Cv = 600e-6/3*m;
Lv = 40e-3*3/m;

% (iL0,uC0)
rng(m+10*n)
x0_slx = [(-1)^(n+1)*E/R,E/3/(1-u_star)];

Ts = 1e-5*(1+2*(u_star-0.15)/u_star); % fundamental step size
Ts = round(Ts*1e6)/1e6;

% input white noise power and sampling time
whtn_pow_in = 1e-11*(Ts*1e4)/2; 
whtn_Ts_in = Ts*2;
whtn_seed_in = 23341+m+2*n;
q_in = (umax-umin)/pow2(11); % input quantizer (DAC)

% output white noise power and sampling time
whtn_pow_out = 1e-7*E*(Ts*1e4/50)*(1+(50*u_star)*(u_star-0.15))/3; 
whtn_Ts_out = Ts*2;
whtn_seed_out = 23342-m-2*n;
q_out = (ymax-ymin)/pow2(11); % output quantizer (ADC)

meas_rep = 13+ceil(n/2); % data acquisition hardware sampling limitation

%% Input setup (can be changed/replaced/deleted)
%Tfin = 2; % simulation duration
%t0 = Tfin/4;
%t1 = Tfin/2;
t1=0.20;
N = 5;
tr = 0.042*2;
p=round(tr/N/Ts);
DeltaT = p*(2^N-1)*Ts*2;
[input_LUT_dSPACE,Tfin] = generate_input_signal(Ts,t1,DeltaT,N,p,u_star,delta,delta_spab);




%% Data acquisition (use t, u, y to perform system identification)
out = sim("convertor_R2025a.slx");

t = out.tout;
u = out.u;
y = out.y;

figure
subplot(211)
plot(t,u)
subplot(212)
plot(t,y)

%% System identification
i1 = 26288;
i2 = 76769;
i3 = 94880;
i4 = 144813;

D=19;

t_id = t(i1:D:i2); % Time vector for identification
u_id = u(i1:D:i2);% Input signal for identification
u_id = u_id-mean(u_id);
y_id = y(i1:D:i2); % Output signal for identification
y_id = y_id-mean(y_id);
 
y_id = medfilt1(y_id,21);

t_vd = t(i3:D:i4); % validare
u_vd = u(i3:D:i4);
u_vd = u_vd-mean(u_vd);
y_vd = y(i3:D:i4);
y_vd = y_vd-mean(y_vd);

y_vd = medfilt1(y_vd,21);

%y_id = detrend(y_id, 'constant');
%y_vd = detrend(y_vd, 'constant');

figure 
subplot(2,2,1)
plot(t_id, u_id)
subplot(2,2,3)
plot(t_id,y_id)
subplot(222)
plot(t_vd,u_vd)
subplot(224)
plot(t_vd,y_vd)

dat_id = iddata(y_id,u_id,t_id(2)-t_id(1));
dat_vd = iddata(y_vd,u_vd,t_vd(2)-t_vd(1));

%%

model_arx = arx(dat_id,[2 2 1]); %timp mort 1 tact din cauza calculatorului
figure,resid(model_arx,dat_vd)
figure,compare(model_arx,dat_vd) 


%%

model_armax=armax(dat_id,[2 2 5 1]);
figure,resid(model_armax,dat_vd)
figure,compare(model_armax,dat_vd)

%%

model_oe = oe(dat_id,[2 2 1]);
figure,resid(model_oe,dat_vd)
figure,compare(model_oe,dat_vd)


%%

model_n4sid = n4sid(dat_id,3)
figure,resid(model_n4sid,dat_vd)
figure,compare(model_n4sid,dat_vd)

%% 

model_ssest = ssest(dat_id,3)
figure,resid(model_ssest,dat_vd)
figure,compare(model_ssest,dat_vd)

%%

model_iv4 = iv4(dat_id, [2 2 3]);
figure, resid(model_iv4, dat_vd)
figure, compare(model_iv4, dat_vd)

%% 

model_bj = bj(dat_id, [2 2 2 2 2]);
figure, resid(model_bj, dat_vd)
figure, compare(model_bj, dat_vd)

%% 

model_fir = impulseest(dat_id, 100);
figure, resid(model_fir, dat_vd)
figure, compare(model_fir, dat_vd)

%%

model_pem = pem(dat_id, model_oe);
figure, resid(model_pem, dat_vd)
figure, compare(model_pem, dat_vd)

%%

model_ssreg = ssregest(dat_id, 2);
figure, resid(model_ssreg, dat_vd)
figure, compare(model_ssreg, dat_vd)

%% 

model_tf = tfest(dat_id, 2,1); 
figure, resid(model_tf, dat_vd)
figure, compare(model_tf, dat_vd)