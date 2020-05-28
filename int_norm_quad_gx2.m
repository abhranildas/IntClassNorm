function [p,pc]=int_norm_quad_gx2(mu,v,quad,varargin)
% Find the probability that a quadratic form of a normal variate x
% x'a2x + a1'x + a0 >= 0
% using the generalized chi-squared CDF (Imhof's method).
%
% How to use this command:
% See github readme at https://github.com/abhranildas/classify
%
% Credits:
%   Abhranil Das <abhranil.das@utexas.edu>
%	Wilson S Geisler
%	Center for Perceptual Systems, University of Texas at Austin
% If you use this code, please cite:
%   A new method to compute classification error
%   https://jov.arvojournals.org/article.aspx?articleid=2750251

parser = inputParser;
addRequired(parser,'mu',@isnumeric);
addRequired(parser,'v',@isnumeric);
addRequired(parser,'quad');
addParameter(parser,'AbsTol',1e-10);
addParameter(parser,'RelTol',1e-2);
parse(parser,mu,v,quad,varargin{:});

AbsTol=parser.Results.AbsTol;
RelTol=parser.Results.RelTol;

% standardize  coefficients
a2=sqrtm(v)*quad.a2*sqrtm(v);
a1=sqrtm(v)*(2*quad.a2*mu+quad.a1);
a0=mu'*quad.a2*mu+quad.a1'*mu+quad.a0;

if ~nnz(a2) % if a2 is zero, linear discriminant
    p=normcdf(a0/norm(a1));
    pc=normcdf(-a0/norm(a1)); % complement of p. It's useful to return it when small, and p is rounded to 1.
else
    % get generalized chi-squared parameters
    [lambda,m,delta,c]=norm_quad_to_gx2_params(mu,v,quad);
    
    % use Imhof's method to compute the CDF.
    if (AbsTol==1e-10)&&(RelTol==1e-6)
        [pc,flag_pc]=gx2cdf_imhof(0,lambda,m,delta,c);
        [p,flag_p]=gx2cdf_imhof(0,lambda,m,delta,c,'upper');
    else
        [pc,flag_pc]=gx2cdf_imhof(0,lambda,m,delta,c,'AbsTol',AbsTol,'RelTol',RelTol);
        [p,flag_p]=gx2cdf_imhof(0,lambda,m,delta,c,'upper','AbsTol',AbsTol,'RelTol',RelTol);
    end
    if flag_p || ((p<1e-3)&&(all(lambda>=0)||all(lambda<=0))) % use approximation for upper tail of definite quadratic
        warning('Using tail approximation.')
        p=gx2cdf_imhof(0,lambda,m,delta,c,'upper','approx','tail');
    end
    if flag_pc % use tail approximation
        warning('Using tail approximation.')
        pc=gx2cdf_imhof(0,lambda,m,delta,c,'approx','tail');
    end
end
