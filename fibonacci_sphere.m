function points=fibonacci_sphere(n_pts)
% Fibonacci sphere algorithm for evenly distributed
% points on a sphere, translated from:
% https://stackoverflow.com/a/26127012/711017
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

offset=2./n_pts;
increment=pi*(3-sqrt(5));
i=(0:n_pts-1)';
y=i*offset-1 + offset/2;
r=sqrt(1-y.^2);
phi=mod(i+1,n_pts)*increment;
points=[r.*cos(phi), y, r.*sin(phi)]';
end