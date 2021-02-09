close all
clear all
clc
%The script outputs 2 plots: (velocity vs time) and (mass vs time to reach 60).
%Also outputs Mass vs Time to reach 60 as a 2 row table and to a .mat file
%Paste this parameter array(with brackets)for GM EV1: [0.95 11 0.3 140 0.0048 733 80 1540 1 1.25 1.8 0.19 1 0]
properties= num2cell(input('Enter the following parameter array without the dots:\n[Efficiency in decimal. Gear Ratio. Wheel Radius. Maximum Torque. Coeff. of friction. Crtical speed in rps. \nMaximum Controller speed in mph if any(0 if N/A). Mass. Correction for inertia in %. Air Density.\n Frontal Area. Drag Coeff. Motor Type: 1 for Induction type and 2 for Lynch type. k, the slope of the torque curve of the motor\n'));
[efficiency, gRatio, r, maxT, friction, wc, maxV, mass, correction, airDensity, area, drag, motorType, k]=properties{:};
[t,v,time]=velocityPlot(efficiency, gRatio, r, maxT, friction, wc, maxV, mass, correction, airDensity, area, drag,motorType,k); % for GM EV1
figure(1)
plot(t,v.*(1/0.44704)); hold on ; plot(time,60,'r*');text(time+0.5,60,[ '(' num2str(time),',' ' ' num2str(60) ')']);
xlabel('Time / seconds');ylabel('velocity /mph');title('Velocity vs Time plot of GM EV1 electric car'); 
axis([0 15 0 90]);

massRow = zeros(9,1);timeRow=zeros(9,1);
for n=1:9
    newMass=mass*(1-0.25+(n*0.05));
    [t,v,time]=velocityPlot(efficiency, gRatio, r, maxT, friction, wc, maxV, newMass, correction, airDensity, area, drag,motorType,k);
    massRow(n,1)=newMass;
    timeRow(n,1)=time;
end

tbl=array2table([massRow timeRow]');tbl.Properties.RowNames={'Mass','Time to reach 60mph'};
tbl
figure(2)
plot(timeRow,massRow, '-ro');
xlabel('Time to reach 60mph');ylabel('Masses');title('Effect of mass on time to reach 60');
save('Mass_vs_Time.mat','tbl')

function [t,v,time]= velocityPlot(efficiency, gRatio, r, maxT, friction, wc, maxV, mass, correction, airDensity, area, drag,motorType,k)
    % maxV is the maximum velocity if any. Enter 0 if not available.
    flag=1;
    t=linspace(0,20,201);  % 0 to 20 seconds, in 0.1 second steps
    v=zeros(1,201);
    cMass = mass + mass*correction/100;
    criticalVelocity = r*wc/gRatio;
    maxV = maxV*0.44704; %unit conversion from mph to m/s
    for n=1:200
       if(flag&&v(n)>30)%wait until velocity reaches 30m/s(67mph) for sufficient interpolation accuracy
           flag=0;
           time=interp1(v(1:n),t(1:n),[26.82]); %interpolate time to get to 26.82 m/s i.e., 60mph
       end
       torque = (maxT*criticalVelocity/v(n))*(motorType==1) + (maxT - k*gRatio*v(n)/r)*(motorType==2); %using logic operators to choose torque after critical velocity.
       if v(n)< criticalVelocity
          v(n+1) = v(n) + 0.1*( (efficiency*gRatio*maxT/r) - (friction*mass*9.8) - (0.5*airDensity*area*drag*(v(n)^2)) )/cMass;
       elseif(maxV && v(n)>maxV) %if maxV exists and if current velocity exceeds maxV
          v(n+1) = v(n);
       else
          v(n+1) = v(n) + 0.1 * ( (efficiency*gRatio*torque/r) - (friction*mass*9.8) - (0.5*airDensity*area*drag*(v(n)^2)) )/cMass;
       end  
    end
end