function [pval, post_prob] = compare_covariances(X1, X2, varargin)
    % compare_covariances tests if the covariances of two samples are different.
    % 
    % Inputs:
    %   X1, X2   - Data matrices (rows = observations, columns = variables)
    %   plotmode - (Optional) Logical flag to plot the null distribution (default: true)
    %
    % Outputs:
    %   pval       - The permutation-based p-value
    %   post_prob  - The posterior probability of different covariances
    
    % Parse inputs
    p = inputParser;
    addRequired(p, 'X1', @isnumeric);
    addRequired(p, 'X2', @isnumeric);
    addParameter(p, 'plotmode', true, @islogical);
    parse(p, X1, X2, varargin{:});
    plotmode = p.Results.plotmode;
    
    % 1. Center the data (subtract mean vectors)
    X1_centered = X1 - mean(X1, 1);
    X2_centered = X2 - mean(X2, 1);
    
    % Get sample sizes
    N1 = size(X1_centered, 1);
    N2 = size(X2_centered, 1);
    
    % Compute the true Posterior Probability
    post_prob = computePosterior(X1_centered, X2_centered, N1, N2);
    
    % 2. Compute the null distribution via permutation
    num_permutations = 1000;
    null_post = zeros(num_permutations, 1);
    
    % Pool the centered data
    X_pooled = [X1_centered; X2_centered];
    N_total = N1 + N2;
    
    for i = 1:num_permutations
        % Randomly permute class labels (indices)
        idx = randperm(N_total);
        
        % Split into two new simulated samples
        Y1 = X_pooled(idx(1:N1), :);
        Y2 = X_pooled(idx(N1+1:end), :);
        
        % Compute Posterior for this permutation
        null_post(i) = computePosterior(Y1, Y2, N1, N2);
    end
    
    % 3. Calculate p-value
    % The p-value is the proportion of null posteriors greater than or equal to the true posterior
    pval = sum(null_post >= post_prob) / num_permutations;
    
    % 4. Plotting
    if plotmode
        figure;
        histogram(null_post, 30, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none');
        hold on;
        
        % Draw vertical line at the true posterior
        xline(post_prob, '-k', 'LineWidth', 1);
        
        % Formatting
        title(sprintf('p = %g', pval));
        xlabel('Posterior probability of diff. covariances');
        legend('null distribution', 'true value', 'Location', 'best');
        legend box off
        hold off;
        set(gca,'ytick',[],'fontsize',13)
    end
end

% --- Helper Function ---
function post_val = computePosterior(Z1, Z2, N1, N2)
    % Assumes zero-mean data, computes ML covariances and the Posterior
    N_tot = N1 + N2;
    
    % Maximum Likelihood Covariances (divided by N, not N-1)
    S1 = (Z1' * Z1) / N1;
    S2 = (Z2' * Z2) / N2;
    S0 = (Z1' * Z1 + Z2' * Z2) / N_tot; % Balanced pooled covariance
    
    % Log-Likelihood Ratio formulation (LLR = L_diff - L_same)
    llr_val = (N_tot / 2) * log(det(S0)) ...
            - (N1 / 2) * log(det(S1)) ...
            - (N2 / 2) * log(det(S2));
            
    % Convert LLR to Posterior Probability (assuming equal priors)
    post_val = 1 / (1 + exp(-llr_val));
end