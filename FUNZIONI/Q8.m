function [outputArg1,x_zp] = Q8(inputArg1,mode)
    if mode == 1            %symmetric to symmetric_max
        max_q = 127;
        min_q = -127;
        max_v = max(inputArg1,[],'all');
        min_v = min(inputArg1,[],'all');
        max_v = max(abs(max_v),abs(min_v));
        min_v = -max_v;
    elseif mode == 2
        max_q = 127;        %symmetric to symmetric_min
        min_q = -127;
        max_v = max(inputArg1,[],'all');
        min_v = min(inputArg1,[],'all');
        max_v = min(abs(max_v),abs(min_v));
        min_v = -max_v;
    elseif mode == 3       %asymmetric to asymmetric
        max_q = 127;
        min_q = -128;
        max_v = max(inputArg1,[],'all');
        min_v = min(inputArg1,[],'all');
    elseif mode == 4
        sigma=std(inputArg1(:));
        mu=mean(inputArg1(:));
        max_q = 127;
        min_q = -127;
        max_v = 3*sigma
        min_v = -3*sigma
    end    
        x_scale = (max_v - min_v) / (max_q - min_q);
        x_zp = round(max_q - max_v / x_scale);
        outputArg1 = int8(round(inputArg1 / x_scale + x_zp));

end    