clear all;
clc;
close all;
format long G;

state(1) = 0;
t = 1;
count = 0;
INPUT_MAT_EMA = table2cell(readtable('DIFFERENZE_EMA_2_2.csv'));
INPUT_MAT_RAW = table2cell(readtable('DIFFERENZE_RAW_2.csv'));
EMA_VALUES = int32(cell2mat(INPUT_MAT_EMA(:,4:13)));
EMA_DISTANCE = int32(cell2mat(INPUT_MAT_EMA(:,14)));
RAW_DISTANCE = int32(cell2mat(INPUT_MAT_EMA(:,14)));
RAW_VALUES = int32(cell2mat(INPUT_MAT_RAW(:,4:13)));
ft = RAW_VALUES - EMA_VALUES;
%dt = sqrt(sum((ft.^2),2));
dt = sum(abs(ft),2);
%dtT ./ dtE
%dt = sum((abs(ft)),2)./2;
%dt = sum((abs(ft)./2),2);
cont = [1:1:356];
%[cont' EMA_DISTANCE] 
[cont' dt EMA_DISTANCE]

fileID = fopen('RAW.txt','w+');
for j=1:size(RAW_VALUES,1)
    for i=1:size(RAW_VALUES,2)
        nbytes = fprintf(fileID,'%d \n', int32(RAW_VALUES(j,i)));
    end
end
fclose(fileID);

fileID = fopen('EMA.txt','w+');
for j=1:size(EMA_VALUES,1)
    for i=1:size(EMA_VALUES,2)
        nbytes = fprintf(fileID,'%d \n', int32(EMA_VALUES(j,i)));
    end
end
fclose(fileID);


while(t ~= length(EMA_VALUES))
    
    if state(t) == 0
        while (t~=16)
            if (t == length(EMA_VALUES)) break; end
            state(t) = 0;
            t = t + 1;
        end
        state(t) = 1;
    end

    if state(t) == 1
        while (t ~= length(EMA_VALUES))
            Edt = mean(dt((t-15):t,:));
            if Edt < 200
                state(t) = 2;   
                break;
            end
            t = t + 1;
            state(t) = 1;
        end
    end

    if state(t) == 2
        while(t ~= length(EMA_VALUES))
            if dt(t) > 200
                state(t) = 3;
                break;
            end
            t = t + 1;
            state(t) = 2;
        end
    end

    if state(t) == 3
        while(t ~= length(EMA_VALUES))
            if dt(t) < 200
                state(t) = 2;
                count = 0;
                break;
            end
            if dt(t) > 200
                count = count + 1;
            end
            if count == 5
                state(t) = 4;
                break;
            end
         t = t + 1;  
         state(t) = 3;
        end
    end

    if state(t) == 4
        for i=1:16
            if (t == length(EMA_VALUES)) break; end
            t = t + 1;
            state(t) = 4;
        end
        state(t) = 1;
    end
  
 
end
    
for i=1:length(state)
    if state(i) == 0
        fprintf("%d WT \n",i);
    elseif state(i) == 1
        fprintf("%d BA \n",i);
    elseif state(i) == 2
        fprintf("%d BT \n",i);
    elseif state(i) == 3
        fprintf("%d BSP \n",i);
    elseif state(i) == 4
        fprintf("%d BS \n",i);
    end
end
    
