clear all;
clc;
close all;
format long G;
conf_mat = 0; %0_disabilitate_1_abilitate_singole_2_abilitata_globale_3_tutte
%-------------------------------CREAZIONE_FOLD
N_fold = 1;
classnames = ["1_TATP";"2_H2O2";"3_SWW";"4_ACETONE";"5_AMMONIA";"6_ACETICACID";"7_FORMICACID";"8_PHOSPHORICACID";"9_DW_DETERGENT";"10_ETHANOL";"11_INT_NELSEN";"12_SODIUM_CHLORIDE";"13_SODIUM_HYPOCHLORITE";"14_SULPHIRICACID";"15_WM_DETERGENT"];
load('DatasetMATLAB_WATER_15_005_4'); %dataset training
load('Test_FORMICACID_02'); % dati sperimentali
Mat_train_tensor = zeros(size(Training3MATLAB,1),size(Training3MATLAB,2),N_fold);
Mat_test_tensor = zeros(size(Test_Dataset,1),size(Test_Dataset,2),N_fold);
Mat_train_tensor(:,:,1)= Training5MATLAB;
Mat_test_tensor(:,:,1) = Test_Dataset;


%-------------------------PARAMETRI
N_class = 15;
N_kernel = 64;
N_train = size(Training3MATLAB,1);
N_test = size(Test_Dataset,1);
N_features = size(Training3MATLAB,2) - 1;
pos_label = size(Training3MATLAB,2);
lambda = 10^(-2);
beta = zeros(N_kernel,N_class);


%-------------------------CREAZIONE_ETICHETTE
Y_train = zeros(N_train,N_class,N_fold);

for kk=1:N_fold

    for k=1:N_class
        for i=1:N_train
            if Mat_train_tensor(i,pos_label,kk) == k
                Y_train(i,k,kk) = 1;
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
end
end
