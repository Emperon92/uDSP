clear all;
clc;
close all;
format long G;
conf_mat = 3;
%-------------------------------

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

%------------------
N_class = 15;
%N_kernel = 16;
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
N_train = size(Training1MATLAB,1);
N_test = size(Test1MATLAB,1);

% inizializzazione a zero:
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


%-------------------------MLP
hidden_layer = 128;                  % Middle Layer Neurons
output_layer = 15;                   % Output Layer Neurons
s_par = sigapprox(1);
s_parVHDL = sigapproxVHDL(128);

% Training parameters
eta = 0.05; % Learning Rate 0-1   eg .01, .05, .005
epoch=100;  % Training iterations

c = zeros(1,N_train);
c_v = zeros(1,N_test);
c_vq = zeros(1,N_test);
c_vq8 = zeros(1,N_test);
SE = zeros(epoch,N_train);
MSE = zeros(1,epoch);
TCE = zeros(1,epoch);
Y_CLASS_V = zeros(N_test,N_fold);
Y_PRED_V = zeros(N_test,N_fold);
Y_CLASS_VQ = zeros(N_test,N_fold);
Y_PRED_VQ = zeros(N_test,N_fold);
Y_PRED_VQ_8 = zeros(N_test,N_fold);
TVE = zeros(1,epoch);
TVE_q = zeros(1,N_fold);
TVE_q8 = zeros(1,N_fold);
TVE_FOLD = zeros(1,N_fold);
Output = zeros(N_train,N_class);

%status training

s = @(z) 1./(1 + exp(-z)); %sigmoid function
ds = @(z) s(z).*(1-s(z));  %sigmoid derivative

for kk=1:N_fold
    w1=randn(N_features,hidden_layer);    % Initial weights of input and middle layer connections
    w2=randn(hidden_layer,N_class);   % Initial weights of middle and output layer connections
    b1=ones(1,hidden_layer);
    b2=ones(1,N_class);
    for j=1:epoch 
            r = randperm(N_train); 
            X_MLP(:,:) = Mat_train_tensor(r,1:pos_label-1,kk);
            Y_MLP(:,:) = Y_train(r,:,kk);
        for k=1:N_train
            
            Input = X_MLP(k,:);  
            labels = Y_MLP(k,:);
            
            %FORWARD PROPAGATION
            % Input layer
            n1 = s(Input*w1 + b1);  
            % Hidden layer
            n2 = s(n1*w2 + b2);
            Output(k,:) = n2;
            % output layer
            e = labels - Output(k,:);

            %BACKPROPAGATION (stochastic gradient descent based learning rule)
            delta2 = -e.*ds(n1*w2 + b2);
            delta1 = delta2*w2'.*ds(Input*w1 + b1);
            dedw2 = delta2.*n1';
            dedw1 = delta1.*Input';
            w2 = w2 - eta*dedw2;
            w1 = w1 - eta*dedw1;
            b2 = b2 - eta*delta2;
            b1 = b1 - eta*delta1; 
            SE(j,k)= sum(e.^2); % squared error
        end
        MSE(j) = mean(SE(j,:));
        %fprintf("Loss_function: %f \n", MSE(j))  
        %validation
        % Input layer

        for k=1:N_test
            input_test= Mat_test_tensor(k,1:pos_label-1,kk);
            n1 = s(input_test*w1 + b1);
            % Hidden layer
            n2 = s(n1*w2 + b2);
            % output layer
            [~,Y_CLASS_V(k,kk)] = max(Y_test(k,:,kk));
            [~,Y_PRED_V(k,kk)] = max(n2);
            if (Y_CLASS_V(k,kk) == Y_PRED_V(k,kk))
               c_v(k) = 1;
            else
               c_v(k) = 0;
            end
        end
        f = sum(c_v);
        TVE(j) = f / length(c_v);
        %fprintf("Accuracy_Validation: %f \n", TVE(j));
        
    end
    %test_matrix
    TVE_FOLD_ME(kk) = mean(TVE);
    TVE_FOLD(kk) = TVE(epoch);
    fprintf("MLP_Accuracy_Validation_Fold_ME: %f \n", TVE_FOLD_ME(kk))
    fprintf("MLP_Accuracy_Validation_Fold: %f \n", TVE_FOLD(kk))
    if conf_mat == 1
        figure;
    	cmat = confusionmat(Y_CLASS_V,Y_PRED_V);
        cchart = confusionchart(cmat,classnames,'Title', 'Confusion Matrix (average over 1 fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    end
    %------------------------------------------------------------------
    %quantizzazione pesi
    [w1_q,w1_zp] = Q8(w1,3);
    [w2_q,w2_zp] = Q8(w2,1);
    [b1_q,b1_zp] = Q8(b1,3);
    [b2_q,b2_zp] = Q8(b2,3);
    %inferenza quantizzata
    for k=1:N_test
        input_test_q= round(Mat_test_tensor(k,1:pos_label-1,kk)*100);
        n1_q_100 = sLinVHDL(sum(fix((input_test_q.*round(w1*10)')/8),2)' + round(b1*125),s_parVHDL);
        n1_q_8 = sLinVHDL(sum(fix((input_test_q.*double(int8(w1*10))')/8),2)' + round(b1*125),s_parVHDL); %%round(double(b1_q-b1_zp)*16)
        % Hidden layern2
        n2_q_100 = sum(fix((n1_q_100.*round(w2*10)')/128),2)' + round(b2*1000/128);
        n2_q_8 = sum(fix((n1_q_100.*(double(w2_q-w2_zp))')/128),2)' + round(b2*1000/128);  %%round(double(b2_q-b2_zp)/4)
        % output layer
        [~,Y_CLASS_VQ(k,kk)] = max(Y_test(k,:,kk));
        [~,Y_PRED_VQ(k,kk)] = max(n2_q_100);
        [~,Y_PRED_VQ_8(k,kk)] = max(n2_q_8);
        if (Y_CLASS_VQ(k,kk) == Y_PRED_VQ(k,kk))
           c_vq(k) = 1;
        else
           c_vq(k) = 0;
        end
        if (Y_CLASS_VQ(k,kk) == Y_PRED_VQ_8(k,kk))
           c_vq8(k) = 1;
        else
           c_vq8(k) = 0;
        end
    end
    f = sum(c_vq);
    TVE_q(kk) = f / length(c_vq);
    fprintf("MLP_Q_Accuracy_Validation_Fold: %f \n", TVE_q(kk))
    f8 = sum(c_vq8);
    TVE_q8(kk) = f8 / length(c_vq8);
    fprintf("MLP_Q_Accuracy_Validation_Fold_8: %f \n", TVE_q8(kk))   
    if conf_mat == 1
        figure;
    	cmat_q = confusionmat(Y_CLASS_VQ,Y_PRED_VQ);
        cchart = confusionchart(cmat_q,classnames,'Title', 'Confusion Matrix Quantized (average over 1 fold)','RowSummary','row-normalized','ColumnSummary','column-normalized');
    end
    
end
    globalaccuracy_ME = mean(TVE_FOLD_ME);
    fprintf("MLP_Global_Accuracy_ME: %f \n \n",globalaccuracy_ME)
    globalaccuracy = mean(TVE_FOLD);
    fprintf("MLP_Global_Accuracy: %f \n \n",globalaccuracy)
    TVE_q_t = mean(TVE_q);    
    fprintf("MLP_Q_Global_accuracy: %f \n", TVE_q_t)  
    TVE_q8_t = mean(TVE_q8);   
    fprintf("MLP_Q_Global_accuracy:_8: %f \n", TVE_q8_t ) 
    
    
    
if conf_mat == 2 || conf_mat == 3
    for kk=1:N_fold
         cmat(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),Y_PRED_V(:,kk));
         cmat_q_100(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),Y_PRED_VQ(:,kk));
         cmat_q_8(kk,:,:) = confusionmat(Mat_test_tensor(:,pos_label,kk),Y_PRED_VQ_8(:,kk));
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

    
%{
s_par = sigapprox(100);
s_parVHDL = sigapproxVHDL(100);



for kk=1:N_fold    
    for k=1:N_test
        input_test_q=[round(Mat_test_tensor(k,1:pos_label-1,kk)/100)];
        n1_q = sLinVHDL(input_test_q*round(w1) + round(b1*100),s_parVHDL);
        % Hidden layern2
        n2_q = sLinVHDL(n1_q*round(w2) + round(b2*100),s_parVHDL);
        % output layer
        [~,Y_CLASS_VQ(k)] = max(Y_test(k,:,kk));
        [~,Y_PRED_VQ(k)] = max(n2_q);
        if (Y_CLASS_VQ(k) == Y_PRED_VQ(k))
           c_vq(k) = 1;
        else
           c_vq(k) = 0;
        end
    end
    f = sum(c_vq);
    TVE_q(kk) = f / length(c_vq);
    fprintf("MLP_Accuracy_Validation_Fold: %f \n", TVE_q(kk))    
end
TVE_q_t = mean(TVE_q);    
fprintf("MLP_global_accuracy: %f \n", TVE_q_t)    
%}
