%calculation of fins
L=0.02 ; %length of fins in m
z=0.324 ; %breadth of fins in m
t=0.002; %thickness of fins in m
Ac= z*t; %conductive area of fins in m
P= 2*(z+t); %conductive perimeter of fins in m
k=205 ; %thermal conductivity cofficient of material of fins in SI unit
h=20 ; %cofficient of forced convection in SI unit
m=(h*P/(k*Ac))^(0.5); %value of m
Tinf=298  ; %tempreature of ambient air in kelvin
To=345 ; %tempreture of the point x=0
Lc= L+(t/2); %effective fin length in m
eff= (m*k/h)*tanh(m*Lc); %efficiency of fin 
syms x y
f= Tinf+((To-Tinf)/cosh(m*Lc))*cosh(m*(Lc-x)); %variation of tempreature in form of function of x
laplace(f)