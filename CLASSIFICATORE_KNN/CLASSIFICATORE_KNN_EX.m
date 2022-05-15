clear all;
clc;
close all;
format long G;
%----------------CLASSIFICATORE_KNN----------------%
load('DatasetMATLAB_WATER_15_005_4'); %dataset training
load('Test_FORMICACID_02'); %dataset dati sperimentali
N_fold = 1;
classnames = ["1_TATP";"2_H2O2";"3_SWW";"4_ACETONE";"5_AMMONIA";"6_ACETICACID";"7_FORMICACID";"8_PHOSPHORICACID";"9_DW_DETERGENT";"10_ETHANOL";"11_INT_NELSEN";"12_SODIUM_CHLORIDE";"13_SODIUM_HYPOCHLORITE";"14_SULPHIRICACID";"15_WM_DETERGENT"];
%classnames={'1_TATP';'2_H2O2';'3_SWW';'4_ACETONE';'5_ACETICACID';'6_FORMICACID';'7_PHOSPHORICACID';'8_DW_DETERGENT';'9_ETHANOL';'10_INT_NELSEN';'11_SODIUM_CHLORIDE';'12_SODIUM_HYPOCHLORITE';'13_SULPHURICACID';'14_WM_DETERGENT'};
%------------------------------------------------------------------------------INIZIALIZZAZIONE
Mat_train_tensor = zeros(size(Training1MATLAB,1),size(Training1MATLAB,2),N_fold);
Mat_test_tensor = zeros(size(Test_Dataset,1),size(Test_Dataset,2),N_fold);
Mat_train_tensor(:,:,1)=Training5MATLAB;
Mat_test_tensor(:,:,1)=Test_Dataset;
%------------------------------------------------------------------------------PARAMETRI
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
N_train = size(size(Training1MATLAB,1),1);
N_test = size(Test_Dataset,1);
labels_true = zeros(N_test,N_fold);
labels_pred = zeros(N_test,N_fold);
accuracy_vector = zeros(1,N_fold);
%------------------------------------------------------------------------------KNN
for k=1:N_fold
    X_KNN = Mat_train_tensor(:,1:pos_label-1,k);
    Y_KNN = Mat_train_tensor(:,pos_label,k);
    Mdl = fitcknn(X_KNN,Y_KNN,'NumNeighbors',100,'Standardize',0,'BreakTies','nearest','Distance','euclidean'); %normalizzazione disabilitata - numero vicini 100
    X_t =  Mat_test_tensor(:,1:pos_label-1,k);
    %labels_true(:,k) = Mat_test_tensor(:,pos_label,k);
    labels_pred(:,k) = predict(Mdl,X_t); 
end
%------------------calcolo_accuracy_globale