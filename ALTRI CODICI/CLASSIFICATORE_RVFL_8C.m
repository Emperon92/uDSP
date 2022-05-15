clear all;
clc;
close all;
format long G;
conf_mat = 0; %0_disabilitate_1_abilitate_singole_2_abilitata_globale_3_tutte
%-------------------------------CREAZIONE_FOLD
N_fold = 10;
classnames = ["1_TATP";"2_H2O2";"3_SWW";"4_ACETONE";"5_AMMONIA";"6_ACETICACID";"7_FORMICACID";"8_PHOSPHORICACID";"9_DW_DETERGENT";"10_ETHANOL";"11_INT_NELSEN";"12_SODIUM_CHLORIDE";"13_SODIUM_HYPOCHLORITE";"14_SULPHIRICACID";"15_WM_DETERGENT"];
load('DatasetMATLAB_WATER_15_005_4');
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

%-------------------------PARAMETRI
N_class = 15;
N_kernel = 16;
N_train = size(Training1MATLAB,1);
N_test = size(Test1MATLAB,1);
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
lambda = 10^(-3);
beta = zeros(N_kernel,N_class);

%-------------------------CREAZIONE_ETICHETTE
Y_train = zeros(N_train,N_class,N_fold);
Y_test = zeros(N_test,N_class,N_fold);

for kk=1:N_fold

    for k=1:N_class
        for i=1:N_train
            if Mat_train_tensor(i,pos_label,kk) == k
                Y_train(i,k,kk) = 1;
            end
        end
    end

    for k=1:N_class
        for i=1:N_test
            if Mat_test_tensor(i,pos_label,kk) == k
                Y_test(i,k,kk) = 1;
            end
        end
    end
end

%-------------------------INIZIALIZZAZIONE_STRUTTURE_DATI
rng(9);
mu = (-0.8 + (0.8-(-0.8))*rand(N_kernel,N_features));
sigma = 0 + 2.*rand(N_kernel,N_features);
[mu_q, mu_zp] = Q8(mu,1);
[sigma_q, sigma_zp] = Q8(sigma,1);
[in, in_zp] = Q8(Mat_train_tensor(i,1:pos_label-1,kk),1);
mu_q =  double(mu_q);
sigma_q = double(sigma_q);
mu_zp = double(mu_zp);
sigma_zp = double(sigma_zp);
H = zeros(N_train,N_kernel);
Hq = zeros(N_train,N_kernel);
H_test = zeros(N_test,N_kernel);
Hq_test = zeros(N_test,N_kernel);
YY_app = zeros(N_kernel,N_class);
YY_q_app = zeros(N_kernel,N_class);
YY_b = zeros(N_test,N_class);
YY_q_b = zeros(N_test,N_class);
y_pred = zeros(N_test,N_fold);
y_pred_q = zeros(N_test,N_fold);
accuracy_vector_RVFL = zeros(1,N_fold);
accuracy_vector_RVFL_q = zeros(1,N_fold);

%-------------------------CLASSIFICATORE_RVFL
for kk = 1:N_fold
        % azzero le variabili seguenti:
        H=zeros(N_train,N_kernel); % hidden matrix usata nel training
        H_test=zeros(N_test,N_kernel); % hidden matrix usata nel test
        [intr, intr_zp] = Q8(Mat_train_tensor(:,1:pos_label-1,kk),1);
        [inte, inte_zp] = Q8(Mat_test_tensor(:,1:pos_label-1,kk),1);
        for i=1:N_train % righe (training set)
            for jj=1:N_kernel % numero di trasformazioni non-lineari dell'input
                % distanza euclidea normalizzata per la funzione "h":
                H(i,jj) = normal_dist(Mat_train_tensor(i,1:pos_label-1,kk),mu(jj,:),sigma(jj,:));
                Hq(i,jj) = apx_normal_dist8C(intr(i,:),mu_q(jj,:)-mu_zp,sigma_q(jj,:)-sigma_zp);
            end
        end
        Hq = double(Hq);
        I = eye(N_kernel); % matrice identità quadrata
        beta = ((inv((H.')*H + lambda*I))*(H.')*(Y_train(:,:,kk)));
        beta_q = ((inv((Hq.')*Hq + lambda*I))*(Hq.')*(Y_train(:,:,kk)));
        [beta_q, beta_zp] = Q8(beta_q,1);
        beta_q = double(beta_q);
        beta_zp = double(beta_zp);
        for i=1:N_test
            for jj=1:N_kernel
                H_test(i,jj) = normal_dist(Mat_test_tensor(i,1:pos_label-1,kk),mu(jj,:),sigma(jj,:));
                Hq_test(i,jj) = apx_normal_dist8C(inte(i,:),mu_q(jj,:)-mu_zp,sigma_q(jj,:)-sigma_zp); 
            end
        end
        Hq_test = double(Hq_test);
        for j=1:N_test
            for i=1:N_kernel
                YY_app(i,:) = beta(i,:)*H_test(j,i); % YY_app = variabile di appoggio, 
                YY_q_app(i,:) = fix((beta_q(i,:)-beta_zp)*Hq_test(j,i)/1024);
            end
            YY_b(j,:) = sum(YY_app,1);    
            YY_q_b(j,:) = sum(YY_q_app,1);
        end
        % calcolo la posizione dell'indice che contiene il valore massimo
        for i=1:N_test
            [~,idx] = max(YY_b(i,:));
            y_pred(i,kk) = idx;
            [~,idx] = max(YY_q_b(i,:));
            y_pred_q(i,kk) = idx;
        end

        %%% Calcolo dell'accuratezza_floating_point:
        c = Mat_test_tensor(:,pos_label,kk) == y_pred(:,kk);
        f = sum(c);
        accuracy_vector_RVFL(1,kk) = f / length(c);
        fprintf("RVFL_Accuracy_Validation_Fold %f \n", accuracy_vector_RVFL(1,kk));
        %%% Calcolo dell'accuratezza_fixed_point:
        cq = Mat_test_tensor(:,pos_label,kk) == y_pred_q(:,kk);
        fq = sum(cq);
        accuracy_vector_RVFL_q(1,kk) = fq / length(cq);
        fprintf("RVFL - accuracy singolo fold Q %f \n", accuracy_vector_RVFL_q(1,kk));
        
        if conf_mat == 1 || conf_mat == 3
            figure;
            cmat_s = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred(:,kk));
            cmat_s_q = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred_q(:,kk));
            cchart = confusionchart(cmat_s,classnames,'Title', 'Confusion Matrix (average over 1 fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
            figure;
            cchart = confusionchart(cmat_s_q,classnames,'Title', 'Confusion Matrix (average over 1 fold Quantized)','RowSummary','row-normalized','ColumnSummary','column-normalized');
        end

end

global_accuracy_RVFL = mean(accuracy_vector_RVFL);
fprintf("RVFL_Global_Accuracy %f \n \n", global_accuracy_RVFL);
global_accuracy_RVFL_q = mean(accuracy_vector_RVFL_q);
fprintf("RVFL_Global_Accuracy %f \n \n", global_accuracy_RVFL_q);

if conf_mat == 2 || conf_mat == 3
    for kk=1:N_fold
         cmat(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred(:,kk));
         cmat_q(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred_q(:,kk));
    end
    figure;
    cmat_m(:,:)=int32(mean(cmat));
    cchart = confusionchart(cmat_m,classnames,'Title', 'Confusion Matrix (average over all fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    figure;
    cmat_mq(:,:)=int32(mean(cmat_q));
    cchart = confusionchart(cmat_mq,classnames,'Title', 'Confusion Matrix (average over all fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
end
