function quad_s=standard_quad(quad,mu,v)
% standardize quadratic coefficients
s=sqrtm(v); % matrix square root (expensive); compute once
quad_s.q2=s*quad.q2*s;
quad_s.q1=s*(2*quad.q2*mu+quad.q1);
quad_s.q0=mu'*quad.q2*mu+quad.q1'*mu+quad.q0;