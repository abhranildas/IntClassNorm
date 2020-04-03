function coeffs=opt_reg_quad(norm_1,norm_2,varargin)

% parse inputs
parser = inputParser;
addRequired(parser,'norm_1',@isnumeric);
addRequired(parser,'norm_2',@isnumeric);
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

coeffs.a2=inv(v_2)-inv(v_1);
coeffs.a1=2*(v_1\mu_1-v_2\mu_2);
coeffs.a0=mu_2'/v_2*mu_2-mu_1'/v_1*mu_1+...
log((((vals(1,1)-vals(1,2))*priors(1))/((vals(2,2)-vals(2,1))*priors(2)))^2*det(v_2)/det(v_1));