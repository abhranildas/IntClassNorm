function [pval, ChiSq_stat, df] = boxMTest(X1, X2)
    % boxMTest Performs Box's M-test for the equality of two covariance matrices.
    %
    % Inputs:
    %   X1, X2     - Data matrices (rows = observations, columns = variables)
    %
    % Outputs:
    %   pval       - The analytical p-value based on the Chi-square distribution
    %   ChiSq_stat - The corrected M-statistic (approximates Chi-square)
    %   df         - Degrees of freedom used for the test
    
    % Ensure both samples have the same number of variables (p)
    [n1, p] = size(X1);
    [n2, p2] = size(X2);
    if p ~= p2
        error('Samples must have the same number of variables (columns).');
    end
    
    % 1. Compute Unbiased Sample Covariances (divides by n-1)
    S1 = cov(X1);
    S2 = cov(X2);
    
    % 2. Calculate Degrees of Freedom
    v1 = n1 - 1;
    v2 = n2 - 1;
    v_tot = v1 + v2; % Total degrees of freedom (N - k)
    
    % 3. Compute the Pooled Covariance Matrix
    S_pooled = (v1 * S1 + v2 * S2) / v_tot;
    
    % 4. Calculate the raw Box's M Statistic
    M = v_tot * log(det(S_pooled)) - (v1 * log(det(S1)) + v2 * log(det(S2)));
    
    % 5. Apply Box's Correction Factor (C)
    % This scales M so that it properly approximates a Chi-square distribution
    k = 2; % Number of groups
    sum_inv_v = (1/v1) + (1/v2);
    C = ((2*p^2 + 3*p - 1) / (6 * (p + 1) * (k - 1))) * (sum_inv_v - (1/v_tot));
    
    % The final test statistic is the corrected M
    ChiSq_stat = M * (1 - C);
    
    % 6. Calculate Degrees of Freedom for the Chi-square distribution
    df = (p * (p + 1) * (k - 1)) / 2;
    
    % 7. Calculate the p-value
    % It is the probability of observing this Chi-square statistic or larger
    pval = 1 - chi2cdf(ChiSq_stat, df);
end