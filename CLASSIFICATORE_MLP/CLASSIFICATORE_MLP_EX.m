clear all;
clc;
close all;
format long G;
%-------------------------------

N_fold = 1;
classnames = ["1_TATP";"2_H2O2";"3_SWW";"4_ACETONE";"5_AMMONIA";"6_ACETICACID";"7_FORMICACID";"8_PHOSPHORICACID";"9_DW_DETERGENT";"10_ETHANOL";"11_INT_NELSEN";"12_SODIUM_CHLORIDE";"13_SODIUM_HYPOCHLORITE";"14_SULPHIRICACID";"15_WM_DETERGENT"];
load('DatasetMATLAB_WATER_15_005_4'); %dataset training
load('Test_FORMICACID_02'); %dataset sperimentale
Mat_train_tensor = zeros(size(Training1MATLAB,1),size(Training1MATLAB,2),N_fold);
Mat_test_tensor = zeros(size(Test_Dataset,1),size(Test_Dataset,2),N_fold);
Mat_train_tensor(:,:,1)=Training5MATLAB;
Mat_test_tensor(:,:,1) = Test_Dataset;


%------------------
N_class = 15;
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
N_train = size(Training1MATLAB,1);
N_test = size(Test_Dataset,1);


% inizializzazione a zero:
Y_train = zeros(N_train,N_class,N_fold);


for kk=1:N_fold

    for k=1:N_class
        for i=1:N_train
            if Mat_train_tensor(i,pos_label,kk) == k
                Y_train(i,k,kk) = 1;
            end
        end
    end
end

%-------------------------MLP
hidden_layer = 16;                  % Middle Layer Neurons
output_layer = 15;                   % Output Layer Neurons
s_par = sigapprox(1);
s_parVHDL = sigapproxVHDL(128);

% Training parameters
eta = 0.05; % Learning Rate 0-1   eg .01, .05, .005
epoch=10;  % Training iterations

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
        % Input layer
        end
    %------------------------------------------------------------------
    %quantizzazione pesi
    for k=1:N_test
        input_test= Mat_test_tensor(k,1:pos_label-1,kk);
        n1 = s(input_test*w1 + b1);
        % Hidden layer
        n2 = s(n1*w2 + b2);
        % output layer
        [~,Y_PRED_V(k,kk)] = max(n2);
    end
    
    [w1_q,w1_zp] = Q8(w1,3);
    [w2_q,w2_zp] = Q8(w2,1);
    [b1_q,b1_zp] = Q8(b1,3);
    [b2_q,b2_zp] = Q8(b2,3);
    %inferenza quantizzata
    for k=1:N_test
        input_test_q= round(Mat_test_tensor(k,1:pos_label-1,kk)*100);
        n1_q_100 = sLinVHDL(sum(fix((input_test_q.*round(w1*10)')/8),2)' + round(b1*125),s_parVHDL);
        n1_q_8 = sLinVHDL(sum(fix((input_test_q.*(double(w1_q-w1_zp))')/8),2)' + round(b1*125),s_parVHDL); %%round(double(b1_q-b1_zp)*16)
        % Hidden layern2
        n2_q_100 = sum(fix((n1_q_100.*round(w2*10)')/128),2)' + round(b2*1000/128);
        n2_q_8 = sum(fix((n1_q_100.*(double(w2_q-w2_zp))')/128),2)' + round(b2*1000/128);  %%round(double(b2_q-b2_zp)/4)
        % output layer

        [~,Y_PRED_VQ(k,kk)] = max(n2_q_100);
        [~,Y_PRED_VQ_8(k,kk)] = max(n2_q_8);
    end
    
end