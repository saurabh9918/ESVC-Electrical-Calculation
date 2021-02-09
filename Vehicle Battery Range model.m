% USE 'specifications_gmev1.xlsx' for GMEV1 parameters' filename
close all
clear all
clc
fileName=input('Enter specifications'' File Name\n','s');k=num2cell(xlsread(fileName));
[mass,correction,drag,density,area,gRatio,radius,grade,regenRatio,bat,cells,capacity,peukertCoeff,kc,ki,kw,conL,friction,accessoryPower,gearEfficiency,gravity]=k{:};
name='No accessories';
accessoryStatus=input('Enter acessories'' staus: 1-ON 0-OFF\n');
if(accessoryStatus);accessoryPower=800;peukertCoeff=1.16;name='With Accessories';end
load('cycles.mat')% UDDS=1 HWFET=2 US06=3 SFUDS=4 FUDS=5
cn=input('Choose drive-cycle: UDDS=1 HWFET=2 US06=3 SFUDS=4 FUDS=5\n');
v=cycles(:,2*cn);i=300;
while(i<1373)
    if(isnan(v(i)));v=v(1:i-1);break;end % This is the true length of the drive cycle
    i=i+1; % Since drive cycles have different lengths
end
v=v.*0.44704;  
finalDoD(1)=0;cumulativeDistance(1)=0;
internalR =(0.022/capacity)*cells*(bat==1)+(0.006/capacity)*cells*(bat==2); %10h rated for PbA and 3h rated for NiCd
peuCap=((capacity/10)^peukertCoeff*10*(bat==1))+((capacity/3)^peukertCoeff*3*(bat==2));
CR(1)=0;
iterCount=1;

while(finalDoD(iterCount)<1) % Main loop
    [finalDoD(iterCount+1),cycleDistance]=onecycle(v,finalDoD(iterCount),mass,correction,drag,density,area,gRatio,radius,grade,regenRatio,bat,cells,peuCap,peukertCoeff,kc,ki,kw,conL,friction,accessoryPower,gearEfficiency,internalR,gravity );
    cumulativeDistance(iterCount+1)=cumulativeDistance(iterCount)+cycleDistance;
    iterCount=iterCount+1;
end
range1=interp1(finalDoD,cumulativeDistance,[0.800])/1000;
figure(1)
plot(cumulativeDistance./1000,finalDoD,'bx','DisplayName',name);  hold on; grid on;
plot(range1,0.8,'r*','DisplayName','80% DoD point');text(range1+5,0.8,[ '(' num2str(round(range1,2)),' KM,' ' ' num2str(80)  '% DoD)']);%range1+5 is shifting slightly to right for readability. 
xlabel('Distance in KM');ylabel('Depth of Discharge');title('DoD vs Distance plot');axis([0 150 0 1.2]);
legend;

function [lastDoD,distance]=onecycle(v,initialDoD,mass,correction,drag,density,area,gRatio,radius,grade,regenRatio,bat,cells,peuCap,peukertCoeff,kc,ki,kw,conL,friction,accessoryPower,gearEfficiency,internalR,gravity)
    N=size(v);
    DoD(1)=initialDoD;
    CR(1)=DoD(1)*peuCap;
    for i=2:N
        accel=v(i)-v(i-1);
        tractionPower=((friction*mass*9.8)+(0.5*density*area*drag*v(i)^2)+(mass*gravity*sin(grade*pi/180))+(mass*(1+correction/100)*accel))*v(i);
        w=v(i)*gRatio/radius;
        regenFlag = sign(tractionPower); % will give -1 if regen, +1 if driving
        tractionPower=(regenRatio^(regenFlag*(regenFlag-1)/2))*tractionPower; % if under regen i.e.,regenFlag=-1, equation becomes regenRatio*tractionPower
        motorOutput=tractionPower/(gearEfficiency^regenFlag);
        if w==0
            batteryPower=accessoryPower;
        else
            torque=abs(motorOutput)/w;
            motorEfficiency=(torque*w)/((torque*w)+(torque^2*kc)+(ki*w)+(w^3*kw)+conL);
            motorInput=motorOutput/(motorEfficiency^regenFlag);
            batteryPower=motorInput+accessoryPower;
        end
        E=OCV(DoD(i-1),cells,bat);
        if batteryPower>=0
            current=(E-sqrt((E^2)-(4*internalR*batteryPower)))/(2*internalR);
            CR(i)=CR(i-1)+(current^peukertCoeff/3600);
        elseif batteryPower<0
            current=-(E-sqrt((E^2)-(8*internalR*batteryPower)))/(4*internalR);%double internal resistance; power is negative here.
            CR(i)=CR(i-1)-(current/3600);
            endjhm
        DoD(i)=CR(i)/peuCap;
        if (DoD(i)>=0.99)
            lastDoD=1;
            break;
        end
        lastDoD=DoD(i);
        distance=sum(v(1:i));
    end
end

function E=OCV(x,cellNumber,type)
    if(type==1);E= (2.15 - (0.15)*x) * cellNumber; end % Lead Acid
    if(type==2);E= ((-8.2816*x^7 + 23.5749*x^6 - 30*x^5 + 23.7053*x^4 - 12.5877*x^3 + 4.1315*x^2 - 0.8658*x + 1.37)) * cellNumber; end % NiCad
end