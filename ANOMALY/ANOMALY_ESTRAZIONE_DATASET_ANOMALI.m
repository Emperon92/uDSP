clear all;
clc;
close all;
format long G;
conf_mat = 2; %0_disabilitate_1_abilitate_singole_2_abilitata_globale_3_tutte
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
N_train = size(Training1MATLAB,1);
N_test = size(Test1MATLAB,1);
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
%-------------------------CLASSIFICATORE_RVFL
%center_rif = mean(mu(:,:)./sigma(:,:),1);
eu_vec = zeros(15,9000);


for i=1:15
    row_train = find(Mat_train_tensor(:,pos_label,2) == i);
    B(i,:,:) = Mat_train_tensor(row_train,1:pos_label-1,2);
    row_test = find(Mat_test_tensor(:,pos_label,2) == i);
    T(i,:,:) = Mat_test_tensor(row_test(1:1000),1:pos_label-1,2);
    mean_B(i,:) = mean(B(i,:,:),2);
    for k=1:9000
        B_temp(1,:) = B(i,k,:);
        eu_vec(i,k) = sqrt(sum((mean_B(i,:)-B_temp(1,:)).^2,2));
    end
end



%{
for i=1:15
    histfit(eu_vec(i,:))
    figure;
end
%}

for i=1:15
    max_sogl(i) = std(eu_vec(i,:))*5;
end
%histogram(eu_vec(9,:))
max_sogl = [0.40 0.65 0.20 0.50 0.65 0.8 0.66 0.23 7.5 0.80 1.1 2.3 0.15 2.5 10];

%{
for i=1:15
    [M,I] = max(eu_vec(i,:));
    max_sogl(i) = M;
end
%}


for i=1:4
    BS(i,:,:) = downsample(B(i,:,:),100);
end

anomaly = 0;
A = 0;
t = 0;
for jj=1:15
    for k=1:1000
        for i=[11 12 13 14 9 8 6 4 3]
            T_temp(1,:) = T(jj,k,:);
            vec_temp = sqrt(sum((mean_B(i,:) - T_temp(1,:)).^2,2));
            %vec_temp = sqrt(sum((mean_B(15,:) - T_temp(i,:)).^2,2));
            if  vec_temp > max_sogl(i)
                anomaly = anomaly + 1;
            end
        end
        if anomaly == 9
            %disp("anomaly");
            A = A + 1;
        else 
            %fprintf("not anomaly %d \n", anomaly);
            if t == 0 
                Test2MATLAB_A = [T_temp(1,:) jj];
                t = 1;
            else 
                Test2MATLAB_A = [Test2MATLAB_A; T_temp(1,:) jj];
            end
        end
        anomaly = 0;
    end
end
%anomaly
A



for i=[3]
    row_train = find(Mat_train_tensor(:,pos_label,2) == i);
    Training2MATLAB_A = [Mat_train_tensor(row_train,1:pos_label,2)];
end
for i=[4 6 8 9 11 12 13 14]
    row_train = find(Mat_train_tensor(:,pos_label,2) == i);
    Training2MATLAB_A = [Training2MATLAB_A; Mat_train_tensor(row_train,1:pos_label,2)];
end

j=1;

for i = [3 4 6 8 9 11 12 13 14]
    id = Training2MATLAB_A(:,pos_label) == i;
    idt = Test2MATLAB_A(:,pos_label) == i;
    Training2MATLAB_A(id,pos_label) = j;
    Test2MATLAB_A(idt,pos_label) = j;
    j = j+1;
end


for i = [3 4 6 8 9 11 12 13 14]
    id = Training2MATLAB_A(:,pos_label) == i;
    idt = Test2MATLAB_A(:,pos_label) == i;
    Training2MATLAB_A(id,pos_label) = j;
    Test2MATLAB_A(idt,pos_label) = j;
    j = j+1;
end

%{
for i [1 2 5 7 10 15]
    id = Mat_test_tensor(:,pos_label,2) == i
    %}
