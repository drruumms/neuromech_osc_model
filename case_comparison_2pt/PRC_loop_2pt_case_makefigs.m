%PRC Loop
% The 2-Point Case study

clear
load('PRC_loop_2pt_case.mat');

all_fixed_pts = [];
x_vals = [];
%  Draw figs
for ccc = 1:size(c_MAs,2)

    %set feedback strength according to loop
    c_MA = c_MAs(ccc);
    c = c_MA;
    
    %Get stuff to plot
    v = vs{ccc};
    z = zs{ccc};
    t = ts{ccc};
    g1 = g1s{ccc};
    h1p = h1ps{ccc};
    ii = iis{ccc};

% ----  II.  Draw Cycle ----  
figure(1); clf;
 xlim([0, ii*dt]);
subplot(4,1,1); plot(v(:,1),'Linewidth', 4); ylabel('\kappa');
subplot(4,1,2); plot(v(:,2), 'g','Linewidth', 4); hold on; plot(v(:,3), 'r','Linewidth', 4); 
ylabel('V'); legend('V', 'D');
subplot(4,1,3); plot(v(:,4), 'g','Linewidth', 4); hold on; plot(v(:,5), 'r','Linewidth', 4); 
ylabel('A'); legend('V', 'D');
subplot(4,1,4); plot(tanh(v(:,4)-2)+1, 'g','Linewidth', 4); hold on; plot(tanh(v(:,5)-2)+1, 'r','Linewidth', 4); 
ylabel('\sigma(A)'); legend('V', 'D');
figtitle = strcat('Cycle timetraces, c = ', num2str(c));
suptitle(figtitle);
% saveas(gcf, strcat('PRCfigs/cycles/', strcat(figtitle, '.png')));



% ----  II.  Draw iPRC ---- 

figure(2); clf; xlim([0, ii*dt]); 
figtitle = strcat('PRCs, c = ', num2str(c));
suptitle(figtitle);
subplot(3,1,1); plot(z(:,1), 'Linewidth', 4); ylabel('\kappa');
subplot(3,1,2); plot(z(:,2), 'g', 'Linewidth', 4); hold on; plot(z(:,3), 'r','Linewidth', 4); 
ylabel('V'); legend('V', 'D');
subplot(3,1,3); plot(z(:,4), 'g','Linewidth', 4); hold on; plot(z(:,5), 'r','Linewidth', 4); 
ylabel('A'); legend('V', 'D');
% saveas(gcf, strcat('PRCfigs/PRCs/',strcat(figtitle, '.png')));

% ---- III.  CALCULATE G-FUNCTION  ----
figure(3); clf;
tol = 1e-6;
plot(g1,'r', 'linewidth',2); hold on; 
plot(h1p,'g', 'linewidth',2);
plot([0,size(g1,2)],[0,0],'k:','linewidth',2);
% plot(t(Indsg1(1:3)),0*Indsg1(1:3),'ko','Markersize',10);
% plot(t(Indsh1p(1:2)),0*Indsh1p(1:2),'ko','Markersize',10);
plot(find(abs(g1)<=tol),0*find(abs(g1)<=tol),'ko','Markersize',10);
plot(find(abs(h1p)<=tol),0*find(abs(h1p)<=tol),'ko','Markersize',10);
legend('mechanical','proprioceptive','"zero"');
xlabel('time'); 
figtitle = strcat('G-function for NM paired-oscillator model, c = ', num2str(c));
title(figtitle);
% saveas(gcf, strcat('PRCfigs/gfns/',strcat(figtitle, '.png')));

fixed_pts = find(abs(g1)<=tol);
fixed_pts = fixed_pts./ii;
all_fixed_pts = [all_fixed_pts, fixed_pts];
x_vals = [x_vals, repmat(c,size(fixed_pts))];

end

figure(4);
plot(x_vals, all_fixed_pts, '.');

