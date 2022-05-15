clear all;
close all;
clc;
format longG;
% inizializzazione (creo i tensori suddetti):
load('DatasetMATLAB_WATER_15_005_4');
Mat_train_tensor = zeros(size(Training1MATLAB,1),size(Training1MATLAB,2));
Mat_test_tensor = zeros(size(Test1MATLAB,1),size(Test1MATLAB,2));
Mat_train_tensor(:,:)= Training4MATLAB;
Mat_test_tensor(:,:)= Test4MATLAB;
%rimescolo
r = randperm(size(Training1MATLAB,1)); 
Mat_train_tensor(:,:) = Mat_train_tensor(r,:);
r = randperm(size(Test1MATLAB,1)); 
Mat_test_tensor(:,:) = Mat_test_tensor(r,:);

hidden_layer = 16;                  % Middle Layer Neurons
output_layer = 15;                   % Output Layer Neurons
N_train = size(Mat_train_tensor,1);
N_test = size(Mat_test_tensor,1);
Y_test = zeros(N_test,output_layer);
y_pred_q = zeros(N_test,1);
y_pred = zeros(N_test,1);
N_features = size(Training1MATLAB,2) - 1;
pos_label = size(Training1MATLAB,2);
% definiamo un parametro "lambda"

Y_train = zeros(N_train,output_layer);
Y_test = zeros(N_test,output_layer);

for k=1:output_layer
    for i=1:N_train
        if Mat_train_tensor(i,11) == k
            Y_train(i,k) = 1;
        end
    end
end

for k=1:output_layer
    for i=1:N_test
        if Mat_test_tensor(i,11) == k
            Y_test(i,k) = 1;
        end
    end
end


s_par = sigapprox(1);
s_parVHDL = sigapproxVHDL(100);

%----MLP


% Training parameters
eta = 0.05; % Learning Rate 0-1   eg .01, .05, .005
epoch=100;  % Training iterations

c = zeros(1,N_train);
c_v = zeros(1,N_test);
SE = zeros(epoch,N_train);
MSE = zeros(1,epoch);
TCE = zeros(1,epoch);

Output = zeros(N_train,output_layer);

%status training

s = @(z) 1./(1 + exp(-z)); %sigmoid function
ds = @(z) s(z).*(1-s(z));  %sigmoid derivative


w1=round(randn(N_features,hidden_layer));    % Initial weights of input and middle layer connections
w2=round(randn(hidden_layer,output_layer));   % Initial weights of middle and output layer connections
b1=ones(1,hidden_layer);
b2=ones(1,output_layer);

for j=1:epoch 
        r = randperm(N_train); 
        X_MLP(:,:) = Mat_train_tensor(r,1:pos_label-1);
        Y_MLP(:,:) = Y_train(r,:);
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
        input_test=[Mat_test_tensor(k,1:pos_label-1)];
        n1 = s(input_test*w1 + b1);
        % Hidden layer
        n2 = s(n1*w2 + b2);
        % output layer
        [~,Y_CLASS_V(k)] = max(Y_test(k,:));
        [~,Y_PRED_V(k)] = max(n2);
        if (Y_CLASS_V(k) == Y_PRED_V(k))
           c_v(k) = 1;
        else
           c_v(k) = 0;
        end
    end
f = sum(c_v);
TVE(j) = f / length(c_v);
end
TVE_FOLD = mean(TVE);
fprintf("MLP_Accuracy_Validation_Fold: %f \n", TVE_FOLD)


for k=1:N_test
    input_test_q=[round(Mat_test_tensor(k,1:pos_label-1)*100)];
    n1_q(k,:) = sLinVHDL(sum(fix(input_test_q.*round(w1*10)'/8),2)' + round(b1*125),s_parVHDL);
    % Hidden layern2
    n2_q(k,:) = sum(fix(n1_q(k,:).*round(w2*10)'/128),2)' + round(b2*1000/128);
    % output layer
    [~,Y_CLASS_VQ(k)] = max(Y_test(k,:));
    [~,Y_PRED_VQ(k)] = max(n2_q(k,:));
    if (Y_CLASS_VQ(k) == Y_PRED_VQ(k))
       c_vq(k) = 1;
    else
       c_vq(k) = 0;
    end
end
f = sum(c_vq);
TVE_q = f / length(c_vq);
fprintf("MLP_Q_Accuracy_Validation_Fold: %f \n", TVE_q)  


fileID = fopen('MLP_input.txt','w+');
for i=1:N_test
    for j=1:10
        nbytes = fprintf(fileID,'%d \n',round(Mat_test_tensor(i,j).*100));
    end
end
fclose(fileID);


fileID = fopen('MLP_w1.txt','w+');
for i=1:hidden_layer
    for j=1:N_features
        nbytes = fprintf(fileID,'%d,',round(w1(j,i)*10));
    end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);



fileID = fopen('MLP_b1.txt','w+');
for i=1:hidden_layer
    nbytes = fprintf(fileID,'%d,',round(b1(i)*125));
end
fclose(fileID);


fileID = fopen('MLP_w2.txt','w+');
for i=1:output_layer
    for j=1:hidden_layer
        nbytes = fprintf(fileID,'%d,',round(w2(j,i)*10));
    end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);



fileID = fopen('MLP_b2.txt','w+');
for i=1:output_layer
    nbytes = fprintf(fileID,'%d,',round(b2(i)*1000/128));
end
fclose(fileID);


fileID = fopen('n1_q.txt','w+');
for i=1:N_test
    for j=1:hidden_layer
        nbytes = fprintf(fileID,'%d,',n1_q(i,j));
    end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);

fileID = fopen('n2_q.txt','w+');
for i=1:N_test
    for j=1:output_layer
        nbytes = fprintf(fileID,'%d,',n2_q(i,j));
    end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);


