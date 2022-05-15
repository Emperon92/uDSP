clear all;
clc;
close all;
format long G;
%----------------CLASSIFICATORE_KNN----------------%
load('DatasetMATLAB_WATER_15_005_4'); 
N_fold = 10;
classnames = ["1_TATP";"2_H2O2";"3_SWW";"4_ACETONE";"5_AMMONIA";"6_ACETICACID";"7_FORMICACID";"8_PHOSPHORICACID";"9_DW_DETERGENT";"10_ETHANOL";"11_INT_NELSEN";"12_SODIUM_CHLORIDE";"13_SODIUM_HYPOCHLORITE";"14_SULPHIRICACID";"15_WM_DETERGENT"];
conf_mat = 2; %0_disabilitate_1_abilitate_singole_2_abilitata_globale_3_tutte
%------------------------------------------------------------------------------INIZIALIZZAZIONE
Mat_train_tensor = zeros(size(Training1MATLAB,1),size(Training1MATLAB,2),N_fold);
Mat_test_tensor = zeros(size(Test1MATLAB,1),size(Test1MATLAB,2),N_fold);
Mat_train_tensor(:,:,1)=Training1MATLAB;
Mat_train_tensor(:,:,2)=Training2MATLAB;
Mat_train_tensor(:,:,3)=Training3MATLAB;
Mat_train_tensor(:,:,4)=Training4MATLAB;
Mat_train_tensor(:,:,5)=Training5MATLAB;
Mat_train_tensor(:,:,6)=Training6MATLAB;
Mat_train_tensor(:,:,7)=Training7MATLAB;
Mat_train_tensor(:,:,8)=Training8MATLAB; 
Mat_train_tensor(:,:,9)=Training9MATLAB;
Mat_train_tensor(:,:,10)=Training10MATLAB;
Mat_test_tensor(:,:,1)=Test1MATLAB;
Mat_test_tensor(:,:,2)=Test2MATLAB;
Mat_test_tensor(:,:,3)=Test3MATLAB;
Mat_test_tensor(:,:,4)=Test4MATLAB;
Mat_test_tensor(:,:,5)=Test5MATLAB;
Mat_test_tensor(:,:,6)=Test6MATLAB;
Mat_test_tensor(:,:,7)=Test7MATLAB;
Mat_test_tensor(:,:,8)=Test8MATLAB;
Mat_test_tensor(:,:,9)=Test9MATLAB;
Mat_test_tensor(:,:,10)=Test10MATLAB;
%------------------------------------------------------------------------------PARAMETRI
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
N_train = size(Training1MATLAB,1);
N_test = size(Test1MATLAB,1);
labels_true = zeros(N_test,N_fold);
labels_pred = zeros(N_test,N_fold);
accuracy_vector = zeros(1,N_fold);
%------------------------------------------------------------------------------KNN
for k=1:N_fold
    X_KNN = Mat_train_tensor(:,1:pos_label-1,k);
    Y_KNN = Mat_train_tensor(:,pos_label,k);
    Mdl = fitcknn(X_KNN,Y_KNN,'NumNeighbors',300,'Standardize',0,'BreakTies','nearest','Distance','euclidean'); %normalizzazione disabilitata - numero vicini 100
    X_t =  Mat_test_tensor(:,1:pos_label-1,k);
    labels_true(:,k) = Mat_test_tensor(:,pos_label,k);
    labels_pred(:,k) = predict(Mdl,X_t); 
    c = labels_true(:,k) == labels_pred(:,k);
    f = sum(c);
    accuracy_vector(k) = f / length(c);
    fprintf("KNN_Accuracy_Validation_Fold %f \n", accuracy_vector(k));
    %confusion_matrix_abilitate_se_conf_max_1
    if conf_mat == 1 || conf_mat == 3
        figure;
        cmat = confusionmat(labels_true(:,k),labels_pred(:,k));
        cchart = confusionchart(cmat,classnames,'Title', 'Confusion Matrix (average over 1 fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    end
end
%------------------calcolo_accuracy_globale
global_accuracy = mean(accuracy_vector);
fprintf("KNN_Global_Accuracy %f \n \n", global_accuracy );

%------------------confusion_matrix_globale
if conf_mat == 2 || conf_mat == 3
    figure;
    for kk=1:N_fold
             cmat(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),labels_pred(:,kk));   
    end
    cmat_mean(:,:)=int32(mean(cmat));
    cchart = confusionchart(cmat_mean,classnames,'Title', 'Confusion Matrix (average over all folds)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    accuracy_mean_trace = trace(cmat_mean)/sum(cmat_mean,'all') %"trace" somma tutti gli elementi sulla diagonale di una matrice
end