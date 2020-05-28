function coeffs=opt_reg_quad(norm_1,norm_2,varargin)
% parse inputs
parser = inputParser;
addRequired(parser,'norm_1',@isnumeric);
addRequired(parser,'norm_2',@isnumeric);
%addParameter(parser,'llr',0,@(x) isnumeric(x) && isscalar(x));
addParameter(parser,'prior_1',0.5, @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x < 1));
addParameter(parser,'vals',eye(2), @(x) isnumeric(x) && ismatrix(x));
parse(parser,norm_1,norm_2,varargin{:});

% parse inputs
mu_1=norm_1(:,1);
v_1=norm_1(:,2:end);
mu_2=norm_2(:,1);
v_2=norm_2(:,2:end);
priors(1)=parser.Results.prior_1;
priors(2)=1-priors(1);
vals=parser.Results.vals;

coeffs.a2=(inv(v_2)-inv(v_1))/2;
coeffs.a1=v_1\mu_1-v_2\mu_2;

[R_1,~]=chol(v_1);
[R_2,~]=chol(v_2);
logdet_1=2*sum(log(diag(R_1)));
logdet_2=2*sum(log(diag(R_2)));

coeffs.a0=(mu_2'/v_2*mu_2-mu_1'/v_1*mu_1)/2+...
log(((vals(1,1)-vals(1,2))*priors(1))/((vals(2,2)-vals(2,1))*priors(2)))...
+(logdet_2-logdet_1)/2;