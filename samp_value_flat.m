function v=samp_value_flat(x,samp_1,samp_2,varargin)
% Given observation samples and flattened boundary coefficients x, returns the expected value.
% This is maximized to yield the optimal boundary coefficients.
% Credits:
%   Abhranil Das <abhranil.das@utexas.edu>
%	R Calen Walshe
%	Wilson S Geisler
%	Center for Perceptual Systems, University of Texas at Austin
% If you use this code, please cite:
% 1. <a href="matlab:web('https://doi.org/10.1167/jov.21.10.1','-browser')"
% >A method to integrate and classify normal distributions</a>
% 2. <a href="matlab:web('https://arxiv.org/abs/2012.14331','-browser')"
% >Methods to integrate multinormals and compute classification measures</a>

% Note: no inputParser here. This is the objective evaluated thousands of
% times during boundary optimization, so we avoid the per-call parser
% overhead and pass varargin straight through to samp_value.

dim=size(samp_1,2);
q2=zeros(dim);
q2(triu(true(dim)))=x(1:(dim^2+dim)/2);
q2=q2+triu(q2,1)';

quad=struct;
quad.q2=q2;
quad.q1=x(end-dim:end-1);
quad.q0=x(end);

v=samp_value(samp_1,samp_2,quad,varargin{:});