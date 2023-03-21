	function [V] = makeV_right(k,K,L,s,B,H,u);
	

	V = [-(s+2*B)  -s*(2*B + s)*u*(-1 + 4*B*H*k*K + 2*H*k*L*s + 2*H*k*s*u); ...
	     -(s+2*B)  (-2*B - s)*(2*B*K + L*s + 2*s*u + 4*B*H*k*K*s*u + 2*H*k*L*s^2*u + 2*H*k*s^2*u^2); ...
	     2*u*s*k        4*H*k^2*s^2*u^2*(2*B*K + L*s + s*u); ...
	     2*u*s*k        2*k*s*u*(2*B*K + L*s + s*u)*(1 + 2*H*k*s*u)];
