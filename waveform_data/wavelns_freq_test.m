%wavelns_freq_test.m
% test cases for wavelength, frequency plots vs various parameters
%simulates mechanical coupling on discrete neuron-system chain
% with beam equation model, plus extra neural coupling
% and with "nondimensionalized" parameters
% with fine mechanical body grid and thresholded muscle activity

global dim gridsz beta cee eps TF Gamma tau_f c_MA tau_m ...
    delX A S Pa tau_n a I max_step t0 thresholding_on

%TEST PARAMS
isold=0; %=1 for old W, =0 for new W
isupstream = 1; %=1 for upstream coupling, =0 for downstream
inphase = 0;%1=start in-phase init cond, 0= antiphase
gammas = 1e3;
kb = 1;
cees_ma = 1.5; %1:.5:3';
thresholding_on = 1;

wavelengths = zeros(size(gammas,1),size(cees_ma,1));
freqs = zeros(size(gammas,1),size(cees_ma,1));
for aa = 1:size(gammas,1)
    for bb = 1:size(cees_ma,1)
%chain dimension  - number of oscillators
dim = 2;
%improved mechanics factor - gridsize
gridsz = 1;

%proprioception parameters
beta = 0; %ratio of left-right asymmetry in proprioception
cee = 1; %strength of local proprioception
eps = 0; %strength of nonlocal proprioception

%simulation runtime
TF = 600;
tic;    
%mechanical params
gamma = gammas(aa); %mech coupling strength via external viscosity/internal visc
Gamma = gamma/kb;
mu = 5;
tau_f = mu/kb; %mu/kb - internal mechanical timescale - internal viscosity/stiffness
c_MA = cees_ma(bb); %muscle activity mechanical feedback strength = 1/(2adelX) * neural feedback strengths
%timescale of muscle activation
tau_m = 1;

% % Mechanically coupled system 
%make 2nd order centered difference operator A 
%discrete beam PDE matrix with free ends
delX = 1/(gridsz*dim);
e = ones(gridsz*dim,1);
% A = (1/delX^2).*spdiags([e -2*e e], [0 1 2], dim, dim+2);
A = (1/delX^2).*spdiags([e -2*e e], [0 1 2], gridsz*dim, gridsz*dim+2);

%identity
ey = speye(gridsz*dim,gridsz*dim);

%mechanical PDE (gamma/kb I + mu/kb AA')k_t = -AA'(k + cM)
%Gamma = gamma/kb, tauf = mu/kb
RHS_matrix = (Gamma*ey+tau_f*(A*A'))\(-(A*A'));
if thresholding_on == 1
    K_dot = @(t,K, AV, AD) RHS_matrix*(K + c_MA.*(tanh(AV-2)-tanh(AD-2)));
else
    K_dot = @(t,K, AV, AD) RHS_matrix*(K + c_MA.*(AV-AD));
end

%spread operator
rowinds = 1:gridsz*dim;
colinds = repelem(1:dim, gridsz);
S = sparse(rowinds, colinds, ones(gridsz*dim,1));

%proprioceptive averaging matrix
rowinds = repelem(1:dim,gridsz);
colinds = 1:gridsz*dim;
Pa = sparse(rowinds, colinds, (1/gridsz).*ones(gridsz*dim,1));

%neural coupling matrix
W = make_W_connectivity(isold, isupstream);

%continuous voltage model
tau_n = 0.001;
a = 1;
I = 0;
volt_V_dot = @(t,Kappa,volt_V) (1/tau_n).*(volt_V - a.*volt_V.^3 + I + W*Kappa);
volt_D_dot = @(t,Kappa,volt_D) (1/tau_n).*(volt_D - a.*volt_D.^3 + I - W*Kappa);

%muscle eqns: AV' = -AV + (VV-VD)
%             AD' = -AD + (VD-VV)
AV_dot = @(t,volt_V, volt_D, A) (1/tau_m).*(volt_V - volt_D - A);
AD_dot = @(t,volt_V, volt_D, A) (1/tau_m).*(volt_D - volt_V - A);

%pick initial conditions from cycle
%simulate single-oscillator to get limit cycle and pick initial phases
[ T, cycle, tees ] = get_period_single_oscillator();
T_i = size(tees,2); %get index-length of cycle period

init_cond = make_init_cond(cycle, T_i, inphase);

%ODE solve stuff
max_step = 1e-2;
t0 = 0:max_step:TF;

%compile all RHS ode functions into one        
% X(1:gridsz*dim) = gridsz*dim K variables
% X(gridsz*dim+1: gridsz*dim+dim) = dim AV variables
% X(gridsz*dim+1+dim: gridsz*dim+2*dim) = dim AD variables
% X(gridsz*dim+1+2*dim: gridsz*dim+3*dim) = dim volt_V variables
% X(gridsz*dim+1+3*dim: gridsz*dim+4*dim) = dim volt_D variables
ode_rhss = @(t,X) [K_dot(t,X(1:gridsz*dim),S*X(gridsz*dim+1: gridsz*dim+dim),...
            S*X(gridsz*dim+1+dim: gridsz*dim+2*dim)); ...
    AV_dot(t,X(gridsz*dim+1+2*dim: gridsz*dim+3*dim), ...
    X(gridsz*dim+1+3*dim: gridsz*dim+4*dim),X(gridsz*dim+1: gridsz*dim+dim));...
     AD_dot(t,X(gridsz*dim+1+2*dim: gridsz*dim+3*dim), ...
    X(gridsz*dim+1+3*dim: gridsz*dim+4*dim),X(gridsz*dim+1+dim: gridsz*dim+2*dim));...
    volt_V_dot(t, Pa*X(1:gridsz*dim), X(gridsz*dim+1+2*dim: gridsz*dim+3*dim));...
    volt_D_dot(t, Pa*X(1:gridsz*dim), X(gridsz*dim+1+3*dim: gridsz*dim+4*dim));];

tic
[y,t] = run_model(ode_rhss, init_cond);
toc

Kappa = y(:, 1:gridsz*dim)';

% %freq plot
freq_plot(Kappa);

%compute waveform info and plot
[period_cycle, avg_phasediff, wavelength, freq] = compute_phase_lags(Kappa, 0);
% [period_cycle, avg_phasediff, wavelength, freq] = compute_phase_lags(Kappa, 1)
% pause(0.1);

    wavelengths(aa,bb) = wavelength
    avg_pdiffs(aa,bb) = avg_phasediff;
    freqs(aa, bb) = freq
    end
end

% % %freq plot
% freq_plot(Kappa);
% % 
% %waveform plot
waveform_plot(y, period_cycle);
% 

% data_title = strcat('wavedata_gamma_tauf_loop_finemech_muscthresh_newW_eps', num2str(eps),'.mat');
% save(data_title);

% %plot stuff
% figure(1); clf;
% plot(log10(Gammas), wavelengths, '-o', 'MarkerSize', 12);
% % lg_labels1 = {size(taufs,1)};
% % for ii=1:size(taufs,1)
% %     lg_labels1(ii) = {strcat('\tau_f = ', num2str(taufs(ii)))};
% % end
% % legend(lg_labels1);
% xlabel('log_{10}\Gamma'); ylabel('Wavelength');
% 
% 
% figure(2); clf;
% plot(log10(Gammas), avg_pdiffs, '-o', 'MarkerSize', 12);
% xlabel('log_{10}\Gamma'); ylabel('Avg. Phase Diffs');
% % 
% figure(2); clf;
% plot(taufs, freqs, '-o', 'MarkerSize', 12);
% lg_labels2 = {size(Gammas,1)};
% for ii=1:size(Gammas,1)
%     lg_labels2(ii) = {strcat('\Gamma = ', num2str(Gammas(ii),'%.1e'))};
% end
% legend(lg_labels2);
% xlabel('\tau_f'); ylabel('frequency');
% 
% figure(1); clf;
% lg_labels = {8};
% ii=1;
% for bb = 1:size(isold,1)
%         for cc = 1:size(isupstream,1)
%             for dd = 1:size(inphase,1)
%                 plot(log10(Gammas), wavelengths(:,bb,cc,dd), '-o', 'MarkerSize', 12); hold on
%                 lg_labels(ii) = {strcat('is old = ', num2str(isold(bb)), ...
%                     ', is upstream = ', num2str(isupstream(cc)), ...
%                     ', starts in-phase = ', num2str(inphase(dd)))};
%                 ii = ii+1;
%             end
%         end
% end
% legend(lg_labels);
% xlabel('log_{10}\Gamma'); ylabel('Wavelength'); title(strcat('\epsilon = ', num2str(eps)));
%  
% figure(2); clf;
% plot(log10(Gammas), wavelengths(:,bb,cc,dd), '-o', 'MarkerSize', 12); hold on
