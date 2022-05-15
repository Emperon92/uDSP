
function [outputArg1] = function_2(inputArg1,inputArg2,inputArg3)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%floor(inputArg1);
%round(inputArg2);
%floor(inputArg1)-round(inputArg2)
sigma2 = int16(floor(10000 ./ inputArg3));
alfa = int16((int16(floor(inputArg1)-round(inputArg2))) .* sigma2);
%----
app = 0;

for z=1:10
    if alfa(z) <= (-30000) || alfa(z) >= (30000) % alfa maggiore di 3 e minore di -3
        app = 0 + app;
    elseif alfa(z) == 0 % alfa uguale a 0
        app = 1000 + app;
    elseif alfa(z) > (-30000) && alfa(z) <= (-15000) % alfa compreso tra -3 e -1.5
        %app = (alfa(z) / 128) + 200 + app;
        app = -bitshift(-alfa(z),-log2(128),'int16') + 200 + app;
    elseif alfa(z) > (-15000) && alfa(z) < 0 % alfa compreso tra -1.5 e 0
        %app = (alfa(z) / 16) + 1000 + app;
        app = -bitshift(-alfa(z),-log2(16),'int16') + 1000 + app;
    elseif alfa(z) <= (15000) && alfa(z) > 0 % alfa compreso tra 0 e 1.5
        %app = -(alfa(z) / 16) + 1000 + app;
        app = -bitshift(alfa(z),-log2(16),'int16') + 1000 + app; 
    elseif alfa(z) < (30000) && alfa(z) > (15000) % alfa compreso tra 1.5 e 3
        %app = -(alfa(z) / 128) + 200 + app;
        app = -bitshift(alfa(z),-log2(128),'int16') + 200 + app; 
    end
    %sat_det(app);
end
outputArg1 = app;
end



