clear all;
clc;
close all;
format long G;
conf_mat = 1; %0_disabilitate_1_abilitate_singole_2_abilitata_globale_3_tutte
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
lambda = 10^(-2);
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
mu_q =  double(mu_q);
sigma_q = double(sigma_q);
mu_zp = double(mu_zp);
sigma_zp = double(sigma_zp);
H = zeros(N_train,N_kernel);
Hq_100 = zeros(N_train,N_kernel);
Hq_8 = zeros(N_train,N_kernel);
H_test = zeros(N_test,N_kernel);
Hq_test_100 = zeros(N_test,N_kernel);
Hq_test_8 = zeros(N_test,N_kernel);
YY_app = zeros(N_kernel,N_class);
YY_q_100_app = zeros(N_kernel,N_class);
YY_q_8_app = zeros(N_kernel,N_class);
YY_b = zeros(N_test,N_class);
YY_q_100_b = zeros(N_test,N_class);
YY_q_8_b = zeros(N_test,N_class);
y_pred = zeros(N_test,N_fold);
y_pred_q_100 = zeros(N_test,N_fold);
y_pred_q_8 = zeros(N_test,N_fold);
accuracy_vector_RVFL = zeros(1,N_fold);
accuracy_vector_RVFL_q_100 = zeros(1,N_fold);
accuracy_vector_RVFL_q_8 = zeros(1,N_fold);

%-------------------------CLASSIFICATORE_RVFL
for kk = 1:N_fold
        % azzero le variabili seguenti:
        H=zeros(N_train,N_kernel); % hidden matrix usata nel training
        H_test=zeros(N_test,N_kernel); % hidden matrix usata nel test

        for i=1:N_train % righe (training set)
            for jj=1:N_kernel % numero di trasformazioni non-lineari dell'input
                % distanza euclidea normalizzata per la funzione "h":
                H(i,jj) = normal_dist(Mat_train_tensor(i,1:pos_label-1,kk),mu(jj,:),sigma(jj,:));
                Hq_100(i,jj) = apx_normal_dist(Mat_train_tensor(i,1:pos_label-1,kk)*128,mu(jj,:)*100,sigma(jj,:)*100); 
                Hq_8(i,jj) = apx_normal_dist(Mat_train_tensor(i,1:pos_label-1,kk)*128,mu_q(jj,:)-mu_zp,sigma_q(jj,:)-sigma_zp);
            end
        end
        Hq_100 = double(Hq_100);
        Hq_8 = double(Hq_8);
        I = eye(N_kernel); % matrice identità quadrata
        beta = ((inv((H.')*H + lambda*I))*(H.')*(Y_train(:,:,kk)));
        beta_q_100 = round(((inv((Hq_100.')*Hq_100 + lambda*I))*(Hq_100.')*(Y_train(:,:,kk)))*1000000);
        beta_q_8 = ((inv((Hq_8.')*Hq_8 + lambda*I))*(Hq_8.')*(Y_train(:,:,kk)));
        [beta_q_8, beta_zp_8] = Q8(beta_q_8,1);
        beta_q_100 = double(beta_q_100);
        beta_q_8 = double(beta_q_8);
        beta_zp_8 = double(beta_zp_8);
        for i=1:N_test
            for jj=1:N_kernel
                H_test(i,jj) = normal_dist(Mat_test_tensor(i,1:pos_label-1,kk),mu(jj,:),sigma(jj,:));
                Hq_test_100(i,jj) = apx_normal_dist(Mat_test_tensor(i,1:pos_label-1,kk)*128,mu(jj,:)*100,sigma(jj,:)*100); 
                Hq_test_8(i,jj) = apx_normal_dist(Mat_test_tensor(i,1:pos_label-1,kk)*128,mu_q(jj,:)-mu_zp,sigma_q(jj,:)-sigma_zp); 
            end
        end
        Hq_test_100 = double(Hq_test_100);
        Hq_test_8 = double(Hq_test_8);
        for j=1:N_test
            for i=1:N_kernel
                YY_app(i,:) = beta(i,:)*H_test(j,i); % YY_app = variabile di appoggio, 
                YY_q_100_app(i,:) = fix(beta_q_100(i,:)*Hq_test_100(j,i)/1024);
                YY_q_8_app(i,:) = fix((beta_q_8(i,:)-beta_zp_8)*Hq_test_8(j,i)/1024);
            end
            YY_b(j,:) = sum(YY_app,1);    
            YY_q_100_b(j,:) = sum(YY_q_100_app,1);
            YY_q_8_b(j,:) = sum(YY_q_8_app,1);
        end
        % calcolo la posizione dell'indice che contiene il valore massimo
        for i=1:N_test
            [~,idx] = max(YY_b(i,:));
            y_pred(i,kk) = idx;
            [~,idx] = max(YY_q_100_b(i,:));
            y_pred_q_100(i,kk) = idx;
            [~,idx] = max(YY_q_8_b(i,:));
            y_pred_q_8(i,kk) = idx;
        end

        %%% Calcolo dell'accuratezza_floating_point:
        c = Mat_test_tensor(:,pos_label,kk) == y_pred(:,kk);
        f = sum(c);
        accuracy_vector_RVFL(1,kk) = f / length(c);
        fprintf("RVFL_Accuracy_Validation_Fold %f \n", accuracy_vector_RVFL(1,kk));
        %%% Calcolo dell'accuratezza_fixed_point:
        cq_100 = Mat_test_tensor(:,pos_label,kk) == y_pred_q_100(:,kk);
        fq_100 = sum(cq_100);
        accuracy_vector_RVFL_q_100(1,kk) = fq_100 / length(cq_100);
        fprintf("RVFL - accuracy singolo fold 100fixed %f \n", accuracy_vector_RVFL_q_100(1,kk));
        %%% Calcolo dell'accuratezza_quantized_8:
        cq_8 = Mat_test_tensor(:,pos_label,kk) == y_pred_q_8(:,kk);
        fq_8 = sum(cq_8);
        accuracy_vector_RVFL_q_8(1,kk) = fq_8 / length(cq_8);
        fprintf("RVFL - accuracy singolo fold Q %f \n", accuracy_vector_RVFL_q_8(1,kk));
        if conf_mat == 1 || conf_mat == 3
            figure;
            cmat_s = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred(:,kk));
            cchart = confusionchart(cmat_s,classnames,'Title', 'Confusion Matrix (average over all fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
            %cmat_s_q_100 = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred_q_100(:,kk));
            %cmat_s_q_8 = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred_q_8(:,kk));
        end

end

global_accuracy_RVFL = mean(accuracy_vector_RVFL);
fprintf("RVFL_Global_Accuracy %f \n \n", global_accuracy_RVFL);
global_accuracy_RVFL_q_100 = mean(accuracy_vector_RVFL_q_100);
fprintf("RVFL_Global_Accuracy %f \n \n", global_accuracy_RVFL_q_100);
global_accuracy_RVFL_q_8 = mean(accuracy_vector_RVFL_q_8);
fprintf("RVFL_Global_Accuracy %f \n \n", global_accuracy_RVFL_q_8);

if conf_mat == 2 || conf_mat == 3
    for kk=1:N_fold
         cmat(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred(:,kk));
         cmat_q_100(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred_q_100(:,kk));
         cmat_q_8(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),y_pred_q_8(:,kk));
    end
    figure;
    cmat_m(:,:)=int32(mean(cmat));
    cchart = confusionchart(cmat_m,classnames,'Title', 'Confusion Matrix (average over all fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    figure;
    cmat_mq_100(:,:)=int32(mean(cmat_q_100));
    cchart = confusionchart(cmat_mq_100,classnames,'Title', 'Confusion Matrix (average over all fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    figure;
    cmat_mq_8(:,:)=int32(mean(cmat_q_8));
    cchart = confusionchart(cmat_mq_8,classnames,'Title', 'Confusion Matrix (average over all fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
end
