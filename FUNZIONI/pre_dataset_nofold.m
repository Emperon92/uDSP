
clear all;
clc;
close all;



Training = table2cell(readtable('TrainSetCompleto.csv'));


CLASSTEXT={'TATP';'HYDROGENPEROXIDE';'SWW';'ACETONE';'ACETICACID';'FORMICACID';'PHOSPHORICACID';'DW_DETERGENT';'ETHANOL';'INT_NELSEN';'SODIUM_CHLORIDE';'SODIUM_HYPOCHLORITE';'SULPHURICACID';'WM_DETERGENT'};
CLASSNUM=[1;2;3;4;5;6;7;8;9;10;11;12;13;14];
%------
TrainingMATLAB = zeros(size(Training,1),size(Training,2));

%training
[wasfound, idx] = ismember(Training(:,11), CLASSTEXT);
f_values = nan(length(idx), 1);
f_values(wasfound) = CLASSNUM(idx(wasfound));
TrainingMATLAB(:,1:10) = cell2mat(Training(:,1:10));
TrainingMATLAB(:,11) = f_values(:,1);
clear wasfound idx f_values

save('DatasetMATLAB_WATER_15_005_FULL.mat')
disp("done");



