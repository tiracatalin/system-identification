%%
% Nume si prenume: Tira Catalin
%

clearvars
clc

%% Magic numbers (replace with received numbers)
m = 5; 
n = 14; 

%% Process data (fixed, do not modify)
a1 = 2*(0.15+(m+n/20)/30)*(1000+n*300);
a2 = (1000+n*300);
b0 = (2.2+m+n)/5.5;

rng(m+10*n)
x0_slx = [(-1)^n*(-m/10-rand(1)*m/5); (-1)^m*(n/20+rand(1)*n/100)];

%% Experiment setup (fixed, do not modify)
Ts = 20/a1/1e4; % fundamental step size
Tfin = 36/a1*10; % simulation duration

gain = 15;
umin = -gain; umax = gain; % input saturation
ymin = -b0*gain/1.8; ymax = b0*gain/1.8; % output saturation

whtn_pow_in = 1e-9*5*(((m-1)*5+n)/5)/2; % input white noise power and sampling time
whtn_Ts_in = Ts*3;
whtn_seed_in = 23341+m+2*n;
q_in = (umax-umin)/pow2(9); % input quantizer (DAC)

whtn_pow_out = 1e-8*5*(((m-1)*8+n)/5)/2; % output white noise power and sampling time
whtn_Ts_out = Ts*5;
whtn_seed_out = 23342-m-2*n;
q_out = (ymax-ymin)/pow2(9); % output quantizer (ADC)

u_op_region = -(m+n/5)/2; % operating point

%% Input setup (can be changed/replaced/deleted)
wf = 9500 % w oscilatie ~ wn(usor de citit din step) (vedeti experiment regresie)
fmin = wf/2/pi/10;
fmax = wf/2/pi*3;
Ain = 2;


%% Data acquisition (use t, u, y to perform system identification)
out = sim("circuit_electric_R2025a.slx");

t = out.tout;
u = out.u;
y = out.y;

plot(t,u,t,y)
shg

%% System identification
Ay = (-6.39915+23.7145)/2
Au = 2;
K = Ay/Au
K = 3.85;

Ayr = (-3.26+26.85)/2
Aur = 2;
Mr = Ayr/Aur

t1 = 0.0142;
t2 = 0.0135;
wr = pi/(t1-t2)
t_rez = (t1+t2)/2
[~, i_rez] = min(abs(t - t_rez));

r = roots([4*Mr^2,0,-4*Mr^2,0,K^2])

zeta = 0.3482;

wn = wr/sqrt(1-2*zeta^2)

H = tf(K*wn^2,[1,2*zeta*wn,wn^2])

A = [0,1;-wn^2 -2*zeta*wn];
B = [0;K*wn^2];
C = [1,0];
D = 0;
sys=ss(A,B,C,D);

%% Validare t_rez -> t_final (Zona de Filtrare)

ysim1_ss = lsim(sys, u, t, [y(1),(y(2) - y(1)) / Ts]); 
ysim1_tf = lsim(H,u,t);

y_fi = y(i_rez:end);
ysim_ss_fi = ysim1_ss(i_rez:end);
ysim_tf_fi = ysim1_tf(i_rez:end);
t_fi = t(i_rez:end);

J_ss_fi=1/sqrt(length(t_fi))*norm(y_fi-ysim_ss_fi)
eMPN_ss_fi = norm(y_fi - ysim_ss_fi)/norm(y_fi - mean(y_fi))*100

J_tf_fi=1/sqrt(length(t_fi))*norm(y_fi-ysim_tf_fi)
eMPN_tf_fi = norm(y_fi - ysim_tf_fi)/norm(y_fi - mean(y_fi))*100

figure 
plot(t_fi,y_fi,t_fi,ysim_ss_fi)
title('Validare zona filtrare - SS')

figure
plot(t_fi,y_fi,t_fi,ysim_tf_fi,'m')
title('Validare zona filtrare - TF')

%% Validare intreg experimentul

ysim2_ss = lsim(sys,u,t,[y(1),(y(2) - y(1)) / Ts]);
ysim2_tf = lsim(H,u,t);

figure
plot(t,u,t,y,t,ysim2_tf);
title('Validare experiment intreg - TF')
figure 
plot(t,u,t,y,t,ysim2_ss,'m');
title('Validare experiment intreg - SS')


J_ss=1/sqrt(length(t))*norm(y-ysim2_ss);
eMPN_ss = norm(y-ysim2_ss)/norm(y-mean(y))*100

J_tf=1/sqrt(length(t))*norm(y-ysim2_tf);
eMPN_tf = norm(y-ysim2_tf)/norm(y-mean(y))*100

