%graph of tempreature variation of fins tempreature from x=0 to end point
m=9.907734547022379 ; %value of m computed from previous code
Tinf=298 ; %value of temprature of ambient air in kelvin
To=354 ; %value of tempreature at x=0
Lc=0.0210 ; %effective length of the fins
y=Tinf+((To-Tinf)/cosh(m*Lc))*cosh(m*(Lc-x)); %expression of tempreature variation of fin in kelvin
x = 0:0.001:0.0210;
plot(x,y), grid on