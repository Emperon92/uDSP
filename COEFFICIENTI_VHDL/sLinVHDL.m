function s = sLinVHDL(x,par)
xmin = -5*par(1);
xmax = -xmin;
    for i=1:length(x)
        if x(i) == 0
            s(i) = par(1)/2;
        elseif x(i) <= xmin
            s(i) = 0;
        elseif x(i) >= xmax
            s(i) = par(1);
        elseif x(i) > xmin  && x(i) <= par(2)
            s(i) = -bitshift(-x(i),-par(6),'int16') + par(7);
        elseif x(i) > par(2) && x(i) < 0
            s(i) = -bitshift(-x(i),-par(4),'int16') + par(5);
        elseif x(i) >= 0 && x(i) <= par(3) 
            s(i) =  bitshift(x(i),-par(4),'int16') + par(5);
        elseif x(i) > par(3)  && x(i) < xmax
            s(i) = bitshift(x(i),-par(8),'int16') + par(9);    
       end
    end     
end