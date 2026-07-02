samp_1=[normrnd(0,2,5e2,1); normrnd(4,1,1e3,1)];
samp_2=[normrnd(2,1,1e3,1); normrnd(6,2,5e2,1)];
results=classify_normals(samp_1,samp_2,'input_type','samp','samp_opt',false,'vals',[2 0; 0 1]);
axis([-6 12 0 .15])

%%
normals=struct;
normals(1).mu=[1;0]; normals(1).v=.1*eye(2);
normals(2).mu=[0;1]; normals(2).v=.1*eye(2);
normals(3).mu=[-1;0]; normals(3).v=.1*eye(2);
normals(4).mu=[0;-1]; normals(4).v=.1*eye(2);

samples=struct;
for i=1:4
    samples(i).sample=mvnrnd(normals(i).mu,normals(i).v,1e4);
end
vals=diag([1 2 3 4]);
results=classify_normals_multi(samples,'input_type','samp','vals',vals)

%% test efficiency scalar: 1d
mu_1=0; v_1=1;
mu_2=2.5; v_2=1.5;

results=classify_normals([mu_1,v_1],[mu_2,v_2],'d_scale',0.5)

%% test efficiency scalar: 2d
mu_1=[2;4]; v_1=[1 1.5; 1.5 3];
mu_2=[5;0]; v_2=[3 0; 0 1];
d_scale_list=linspace(1,0,10);
for i=1:length(d_scale_list)
    results=classify_normals([mu_1,v_1],[mu_2,v_2],'d_scale',d_scale_list(i))
    axis([0 10 -3 7])
    drawnow
    pause
end

%% d' scaling animation

mu_1=[0;4]; v_1=[1 1.5; 1.5 3];
mu_2=[5;-1]; v_2=[3 0; 0 2];

n_samp=5e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

d_scale_list=linspace(1,0,200);

frames = {};
for i=1:length(d_scale_list)
    i
    results=classify_normals(samp_1,samp_2,'input_type','samp','method','gx2','eff',d_scale_list(i),'samp_opt',false);
    axis image; axis([-5 10 -5 10])
    box on
    set(gca,'xtick',[],'ytick',[])
    title(sprintf("$d' = %.1f$",results.norm_d_b),'interpreter','latex');
    frame = getframe(gcf);
    frames{end+1} = frame;
    close
end

% Create the GIF
gifFileName = 'output.gif';
for i = [1:numel(frames)-1 numel(frames)-1:-1:2]
    im = frame2im(frames{i});
    [A,map] = rgb2ind(im,256);
    if i == 1
        imwrite(A,map,gifFileName,'gif','LoopCount',Inf,'DelayTime',0.03);
    else
        imwrite(A,map,gifFileName,'gif','WriteMode','append','DelayTime',0.03);
    end
end

%% scale d' of non-normal samples

mu_1=[-10;5]; v_1=[10 -2; -2 2]*.5;
mu_2=[5;5]; v_2=[1 1.5; 1.5 3]*.1;

n_samp=5e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

samp_1(:,2)=samp_1(:,2).^2/1.5;
samp_1=samp_1+[-5 10];
samp_2=samp_2.^6/1e3;

results=classify_normals(samp_1,samp_2,'input_type','samp','method','gx2','d_scale',0.5,'d_scale_type','squeeze_dist','samp_opt',false);
axis image; axis([-30 50 -20 100])

%% scale d' of non-normal samples: animation

mu_1=[-10;5]; v_1=[10 -2; -2 2]*.5;
mu_2=[5;5]; v_2=[1 1.5; 1.5 3]*.1;

n_samp=5e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

samp_1(:,2)=samp_1(:,2).^2/1.5;
samp_1=samp_1+[-5 10];
samp_2=samp_2.^6/1e3;

d_scale_list=linspace(1,0,100);

frames = {};
for i=1:length(d_scale_list)
    i
    results=classify_normals(samp_1,samp_2,'input_type','samp','method','gx2','d_scale',d_scale_list(i),'samp_opt',false);
    axis image; axis([-30 60 -20 100])
    box on
    set(gca,'xtick',[],'ytick',[])
    %     title(sprintf("$d' = %.1f$",results.norm_d_b),'interpreter','latex');
    title ''
    text(20,-10,sprintf("$d' = %.0f$",results.norm_d_b),'interpreter','latex','fontsize',20);
    %     set(gca,'fontsize',13)
    frame = getframe(gca);
    frames{end+1} = frame;
    % pause
    close
end

% Create the GIF
gifFileName = 'output.gif';
for i = [1:numel(frames)-1 numel(frames)-1:-1:2]
    im = frame2im(frames{i});
    [A,map] = rgb2ind(im,256);
    if i == 1
        imwrite(A,map,gifFileName,'gif','LoopCount',Inf,'DelayTime',0.03);
    else
        imwrite(A,map,gifFileName,'gif','WriteMode','append','DelayTime',0.03);
    end
end

%% scale d' of non-normal samples: figure for paper
%% warping the distributions

mu_1=[-10;5]; v_1=[10 -2; -2 2]*.3;
mu_2=[6;5]; v_2=[1 1.5; 1.5 3]*.02;

n_samp=5e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

samp_1(:,2)=samp_1(:,2).^2/1.5;
samp_1=samp_1+[-5 10];
samp_2=samp_2.^6/1e3;

d_scale_list=linspace(1,0.05,4);
d_list=nan(size(d_scale_list));
for i=1:length(d_scale_list)
    results=classify_normals(samp_1,samp_2,'input_type','samp','d_scale',d_scale_list(i),'samp_opt',false);
    d_list(i)=results.samp_d_b;
    set(gca,'xtick',[],'ytick',[])
end
axis image; axis([-25 70 0 50])

%% warping the dv

mu_1=[-10;5]; v_1=[10 -2; -2 2]*.3;
mu_2=[6;5]; v_2=[1 1.5; 1.5 3]*.02;

n_samp=5e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

samp_1(:,2)=samp_1(:,2).^2/1.5;
samp_1=samp_1+[-5 10];
samp_2=samp_2.^6/1e3;

d_scale_list=linspace(0.5,0,4);
d_list=nan(size(d_scale_list));
for i=1:length(d_scale_list)
    % figure
    results=classify_normals(samp_1,samp_2,'input_type','samp','d_scale',d_scale_list(i),'d_scale_type','squeeze_dv','samp_opt',false,'plotmode','fun_prob');
    % subplot(4,1,i); hold on
    % histogram(results.samp_dv{1},'edgecolor','none','Normalization','pdf')
    % histogram(results.samp_dv{2},'edgecolor','none','Normalization','pdf')
    % xline(0)
    xlim([-1200 500])
    % set(gca,'xtick',[-1200 0 500],'ytick',[])
    d_list(i)=results.samp_d_b;
end

%% d'-scaling each dimension
mu_1=[2;4]; v_1=[1 1.5; 1.5 3]; S_1=sqrtm(v_1);
mu_2=[5;0]; v_2=[3 -1.5; -1.5 1]; S_2=sqrtm(v_2);

results=classify_normals([mu_1,v_1],[mu_2,v_2]);
axis([0 10 -3 7])

% first scale x. need to scale both variance and covariance
mu_2(1)=mu_1(1);
scale_x=sqrt(v_1(1,1)/v_2(1,1));
v_2(1,1)=v_2(1,1)*scale_x^2;
v_2(1,2)=v_2(1,2)*scale_x;
v_2(2,1)=v_2(2,1)*scale_x;
results=classify_normals([mu_1,v_1],[mu_2,v_2]);
axis([0 10 -3 7])

% then scale y
mu_2(2)=mu_1(2);
scale_y=sqrt(v_1(2,2)/v_2(2,2));
v_2(2,2)=v_2(2,2)*scale_y^2;
v_2(1,2)=v_2(1,2)*scale_y;
v_2(2,1)=v_2(2,1)*scale_y;
results=classify_normals([mu_1,v_1],[mu_2,v_2]);
axis([0 10 -3 7])

%% pulling bayes dv's together
mu_1=[2;4]; v_1=[1 1.5; 1.5 3];
mu_2=[5;0]; v_2=[3 -1.5; -1.5 1];

n_samp=5e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

results=classify_normals(samp_1,samp_2,'input_type','samp','samp_opt',false,'d_scale',0);

%% non-orthogonal contributions to d'
% mu_1=[2;3];
% mu_2=[7;9];
% v=[1 -1.3; -1.3 4];

mu_1=[0;0];
mu_2=[9;9];
v=[1 .8; .8 1];

S=sqrtm(v);

samp_1=mvnrnd(mu_1,v,1e3);
samp_2=mvnrnd(mu_2,v,1e3);

classify_normals(samp_1,samp_2,'input_type','samp','samp_opt',false);
hold on
% axis normal

% plot line between means
plot([mu_1(1), mu_2(1)], [mu_1(2), mu_2(2)], '-k')

% plot rectangular grid
s=sqrt(diag(v));
x_min=mu_1(1)-s(1);
x_max=mu_2(1)+s(1);
y_min=mu_1(2)-s(2);
y_max=mu_2(2)+s(2);

x_grid = x_min:s(1):x_max; % X-coordinates for vertical lines
y_grid = y_min:s(2):y_max; % Y-coordinates for horizontal lines

% Generate endpoints for vertical lines
X_vertical = [x_grid; x_grid]; % Each column is a vertical line
Y_vertical = [y_min * ones(size(x_grid)); y_max * ones(size(x_grid))];

% Generate endpoints for horizontal lines
Y_horizontal = [y_grid; y_grid]; % Each column is a horizontal line
X_horizontal = [x_min * ones(size(y_grid)); x_max * ones(size(y_grid))];

% Plot all vertical and horizontal lines at once
% plot(X_vertical, Y_vertical, 'k-', X_horizontal, Y_horizontal, 'k-');

% plot quarter unit circles
th=linspace(0,2*pi,100);
circ=[sin(th);cos(th)];
circ_x=sqrt(diag(v)).*circ+mu_1;
circ_z=S*circ+mu_1;

plot(circ_z(1,:),circ_z(2,:),'-r')
plot(circ_x(1,:),circ_x(2,:),'-k')

% axis([-1 10 -3 15])
title ''
% set(gca,'xtick',[],'ytick',[],'fontsize',13)

hold on

% plot basis vectors of z
quiver(mu_1(1), mu_1(2), S(1,1), S(2,1), 0, '-r','showarrowhead',0);
quiver(mu_1(1), mu_1(2), S(1,2), S(2,2), 0, '-r','showarrowhead',0);

% whitened space:
samp_1_w=samp_1/S;
samp_2_w=samp_2/S;

mu_1_w=S\mu_1;
mu_2_w=S\mu_2;
v_w=eye(2);

results=classify_normals(samp_1_w,samp_2_w,'input_type','samp','samp_opt',false);

T=inv(S);
hold on

% d' vector
dprime_w=mu_2_w-mu_1_w;
quiver(mu_1_w(1), mu_1_w(2), dprime_w(1), dprime_w(2), 0, 'k','showarrowhead',0);

% projections of d' along original axes
d_1=dot(dprime_w,T(:,1))*T(:,1)/norm(T(:,1))^2;
d_2=dot(dprime_w,T(:,2))*T(:,2)/norm(T(:,2))^2;

% individual dprimes
d=mu_2-mu_1;
dprimes_ind=d./sqrt(diag(v))
dprimes_ind(2)/dprimes_ind(1);

% vector contribution lengths
% delta=d.*(vecnorm(T,2,1))'
delta=d.*sqrt(diag(inv(v)))
delta(2)/delta(1);
c=d;

% plot parallelogram
quiver(mu_1_w(1), mu_1_w(2), c(1)*T(1,1), c(1)*T(2,1), 0, 'k','showarrowhead',0);
quiver(mu_1_w(1), mu_1_w(2), c(2)*T(1,2), c(2)*T(2,2), 0, 'k','showarrowhead',0);

quiver(mu_1_w(1)+c(1)*T(1,1), mu_1_w(2)+c(1)*T(2,1), c(2)*T(1,2), c(2)*T(2,2), 0, 'k','showarrowhead',0);
quiver(mu_1_w(1)+c(2)*T(1,2), mu_1_w(2)+c(2)*T(2,2), c(1)*T(1,1), c(1)*T(2,1), 0, 'k','showarrowhead',0);


% plot original basis
quiver(mu_1_w(1), mu_1_w(2), T(1,1), T(2,1), 0, 'b','showarrowhead',0);
quiver(mu_1_w(1), mu_1_w(2), T(1,2), T(2,2), 0, 'b','showarrowhead',0);

% angles between d' vector and original axes
acosd(sum(dprime_w.*T)./(norm(dprime_w)*vecnorm(T)))

title ''
% axis([0 14.5 -1 10.5])
% set(gca,'xtick',[],'ytick',[],'fontsize',13)

%% d_con_vec
mu_1=[0;0;0];
mu_2=[1;1;1];
v=[1 0  0;
  0  1   0;
  0  0   1];
results=classify_normals([mu_1 v],[mu_2 v]);
S=sqrtm(v);
dprime_w=S\(mu_2-mu_1);
T=inv(S);

sum(dprime_w.*T)./(norm(dprime_w)*vecnorm(T))

%% d' from suboptimal conditions

% 1D, normals
mu_1=0; v_1=1;
mu_2=5; v_2=1;

results=classify_normals([mu_1,v_1],[mu_2,v_2],'prior_1',.7)

bd.q2=0;
bd.q1=-1;
bd.q0=4;

results_sub=classify_normals([mu_1,v_1],[mu_2,v_2],'prior_1',.7,'dom',bd)

% 1D, samples
n_samp=1e4;
samp_1=normrnd(mu_1,sqrt(v_1),[7e4 1]);
samp_2=normrnd(mu_2,sqrt(v_2),[3e4 1]);

results=classify_normals(samp_1,samp_2,'input_type','samp')

results_sub=classify_normals(samp_1,samp_2,'input_type','samp','dom',bd)


% 2D, normals
mu_1=[2;4]; v_1=[1 1.5; 1.5 3];
mu_2=[5;0]; v_2=[3 0; 0 1];

results=classify_normals([mu_1,v_1],[mu_2,v_2])

linear_bd.q2=zeros(2);
linear_bd.q1=[-.7;1];
linear_bd.q0=0;

results_sub=classify_normals([mu_1,v_1],[mu_2,v_2],'dom',linear_bd)

% 2D, samples
n_samp=1e3;
samp_1=mvnrnd(mu_1,v_1,n_samp);
samp_2=mvnrnd(mu_2,v_2,n_samp);

results=classify_normals(samp_1,samp_2,'input_type','samp','samp_opt',100)

results_sub=classify_normals(samp_1,samp_2,'input_type','samp','dom',linear_bd,'samp_opt',100)

%% demo_covariance_test.m
% A simple script to demonstrate the compareCovariances function

% 1. Define parameters for two bivariate distributions
mu1 = [0, 0];
% Covariance 1: Strong positive correlation
Sigma1 = [2.0, 1.5; 
          1.5, 2.0];  

mu2 = [0, 0]; % Different mean (handled by the function's mean subtraction)
% Covariance 2: Negative correlation
Sigma2 = [2.0, 1.55; 
         1.55,  2.0]; 

% Number of observations
N1 = 1e4;
N2 = 1e3;

% 2. Draw samples from the distributions
X1 = mvnrnd(mu1, Sigma1, N1);
X2 = mvnrnd(mu2, Sigma2, N2);

% 3. Plot the raw data to visually inspect the different covariances
figure;
scatter(X1(:,1), X1(:,2), 30, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
hold on;
scatter(X2(:,1), X2(:,2), 30, 'r', 'filled', 'MarkerFaceAlpha', 0.6);
title('Scatter Plot of Two Bivariate Samples');
xlabel('Variable 1');
ylabel('Variable 2');

% 4. Call the function to test if covariances are statistically different
p = compare_covariances(X1, X2, 'plotmode', true)

p_box = boxMTest(X1, X2)

%% A script to evaluate p-value calibration and ROC performance
clear; clc; close all;

% Simulation parameters
num_same = 500; % Number of iterations for the Null hypothesis
num_diff = 500; % Number of iterations for the Alternative hypothesis
N1 = 350;
N2 = 500;
nu = 5; % Degrees of freedom for t-distribution (heavy tails)

% Array of nominal p-value criteria to test (0 to 1)
% Increased to 1000 points to make the ROC curves smoother
alpha_criteria = linspace(0, 1, 1000); 

% =========================================================================
% SIMULATIONS (Null & Alternative Hypotheses)
% =========================================================================
% Initialize arrays to store the raw p-values
p_perm_same = zeros(num_same, 4); p_box_same = zeros(num_same, 4);
p_perm_diff = zeros(num_diff, 4); p_box_diff = zeros(num_diff, 4);

dist_names = {'Normal', 'T-Dist (Heavy Tails)', 'Log-Normal (Skewed)', 'Bimodal'};
fprintf('Running simulations (%d iterations per scenario)...\n', num_same + num_diff);

for d = 1:4
    fprintf('Processing %s data...\n', dist_names{d});
    
    % --- SAME COVARIANCES (Null is True) ---
    for i = 1:num_same
        A = randn(2,2);
        if d == 3, A = A * 0.5; end % Scale down for log-normal
        Sigma = A * A' + eye(2)*0.5; 
        
        [X1, X2] = generate_data(Sigma, Sigma, N1, N2, d, nu);
        
        [p_perm_same(i, d), ~] = compare_covariances(X1, X2, 'plotmode', false);
        [p_box_same(i, d), ~, ~] = boxMTest(X1, X2);
    end
    
    % --- DIFFERENT COVARIANCES (Null is False) ---
    for i = 1:num_diff
        A = randn(2,2);
        if d == 3, A = A * 0.5; end
        Sigma1 = A * A' + eye(2)*0.5;
        
        perturbation_factor = 2 * (i / num_diff); 
        B = randn(2,2);
        if d == 3, B = B * 0.5; end
        Sigma2 = Sigma1 + perturbation_factor * (B * B');
        
        [X1, X2] = generate_data(Sigma1, Sigma2, N1, N2, d, nu);
        
        [p_perm_diff(i, d), ~] = compare_covariances(X1, X2, 'plotmode', false);
        [p_box_diff(i, d), ~, ~] = boxMTest(X1, X2);
    end
end

% =========================================================================
% CALCULATE RATES FOR PLOTTING
% =========================================================================
% Initialize arrays to store the actual FPR and TPR for each nominal criterion
fpr_perm = zeros(length(alpha_criteria), 4); tpr_perm = zeros(length(alpha_criteria), 4);
fpr_box  = zeros(length(alpha_criteria), 4); tpr_box  = zeros(length(alpha_criteria), 4);

for d = 1:4
    for a_idx = 1:length(alpha_criteria)
        current_alpha = alpha_criteria(a_idx);
        
        % False Positive Rate (Fraction of 'Same' cases predicted as 'Different')
        fpr_perm(a_idx, d) = sum(p_perm_same(:, d) <= current_alpha) / num_same;
        fpr_box(a_idx, d)  = sum(p_box_same(:, d) <= current_alpha) / num_same;
        
        % True Positive Rate (Fraction of 'Different' cases predicted as 'Different')
        tpr_perm(a_idx, d) = sum(p_perm_diff(:, d) <= current_alpha) / num_diff;
        tpr_box(a_idx, d)  = sum(p_box_diff(:, d) <= current_alpha) / num_diff;
    end
end

% =========================================================================
% PLOTTING: 2x4 GRID
% =========================================================================
figure

for d = 1:4
    % -----------------------------------------------------------
    % ROW 1: Calibration Curves (Nominal vs Actual FPR)
    % -----------------------------------------------------------
    subplot(2, 4, d);
    hold on; grid on;
    
    % Ideal Calibration Line (y = x)
    plot([0 1], [0 1], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Ideal (y = x)');
    
    % Actual FPRs using plot with dots
    plot(alpha_criteria, fpr_perm(:, d), 'b.', 'MarkerSize', 8, 'DisplayName', 'Permutation LLR');
    plot(alpha_criteria, fpr_box(:, d), 'r.', 'MarkerSize', 8, 'DisplayName', 'Box''s M-Test');
    
    % Formatting
    title(dist_names{d});
    xlabel('Nominal p-value criterion (\alpha)');
    ylabel('Actual False Positive Rate');
    xlim([0 1]); ylim([0 1]);
    axis square;
    if d == 1, legend('Location', 'NW'); end
    hold off;
    
    % -----------------------------------------------------------
    % ROW 2: ROC Curves
    % -----------------------------------------------------------
    subplot(2, 4, d + 4);
    hold on; grid on;
    
    % Reference random-guess line
    plot([0 1], [0 1], 'k--', 'LineWidth', 1.5);
    
    % ROC Curves (FPR vs TPR) using solid lines
    plot(fpr_perm(:, d), tpr_perm(:, d), '.b');
    plot(fpr_box(:, d), tpr_box(:, d), '.r');
    
    % Calculate exact AUCs to put in the title
    auc_p = compute_auc(p_perm_same(:, d), p_perm_diff(:, d));
    auc_b = compute_auc(p_box_same(:, d), p_box_diff(:, d));
    
    % Formatting
    title(sprintf('AUC: Perm=%.3f, Box=%.3f', auc_p, auc_b));
    xlabel('False Positive Rate (FPR)');
    ylabel('True Positive Rate (TPR)');
    xlim([0 1]); ylim([0 1]);
    axis square;
    hold off;
end

% =========================================================================
% HELPER FUNCTIONS
% =========================================================================
function [X1, X2] = generate_data(Sigma1, Sigma2, N1, N2, type, nu)
    switch type
        case 1 % Normal
            X1 = mvnrnd([0 0], Sigma1, N1);
            X2 = mvnrnd([0 0], Sigma2, N2);
        case 2 % T-Distribution
            [C1, sig1] = corrcov(Sigma1);
            [C2, sig2] = corrcov(Sigma2);
            X1 = mvtrnd(C1, nu, N1) .* sig1';
            X2 = mvtrnd(C2, nu, N2) .* sig2';
        case 3 % Log-Normal
            X1 = exp(mvnrnd([0 0], Sigma1, N1));
            X2 = exp(mvnrnd([0 0], Sigma2, N2));
        case 4 % Bimodal
            mu_shift = [3, 3];
            shift1 = (randi([0 1], N1, 1) * 2 - 1) .* mu_shift;
            shift2 = (randi([0 1], N2, 1) * 2 - 1) .* mu_shift;
            X1 = mvnrnd([0 0], Sigma1, N1) + shift1;
            X2 = mvnrnd([0 0], Sigma2, N2) + shift2;
    end
end

function auc = compute_auc(p_same, p_diff)
    % Exact AUC via Wilcoxon rank-sum trick
    scores_neg = 1 - p_same; 
    scores_pos = 1 - p_diff; 
    
    n0 = length(scores_neg);
    n1 = length(scores_pos);
    
    ranks = tiedrank([scores_neg; scores_pos]);
    sum_ranks_pos = sum(ranks(n0 + 1 : end));
    auc = (sum_ranks_pos - n1 * (n1 + 1) / 2) / (n0 * n1);
end

