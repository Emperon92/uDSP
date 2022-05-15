%% --- CREATE LOOKUP TABLE FOR GAUSSIAN KERNEL FUNCTION ---

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

N_class = 15;
N_kernel = 16;
N_train = size(Mat_train_tensor,1);
N_test = size(Mat_test_tensor,1);
Y_test = zeros(N_test,N_class);
y_pred_q = zeros(N_test,1);
y_pred = zeros(N_test,1);
% definiamo un parametro "lambda"
lambda = 10^(-3);

stop=0;
rng(9);
% % normalizzo mu tra -0.8 e 0.8
mu = (-0.8 + (0.8-(-0.8))*rand(N_kernel,10));
sigma = 0 + 2.*rand(N_kernel,10);
%%Q
[mu_q, mu_zp] = Q8(mu,1);
[sigma_q, sigma_zp] = Q8(sigma,1);
mu_q =  double(mu_q);
sigma_q = double(sigma_q);
mu_zp = double(mu_zp);
sigma_zp = double(sigma_zp);

fileID = fopen('coeff.txt','w+');
for j=1:N_kernel
    for i=1:10
        nbytes = fprintf(fileID,'%d,%d,',round(mu(j,i).*100),int16(floor(10000 ./ (sigma(j,i).*100))));
    end
    nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
%%coeff 8bit
fileID = fopen('coeff_8bit.txt','w+');
for j=1:N_kernel
    for i=1:10
        nbytes = fprintf(fileID,'%d,%d,',mu_q(j,i),sigma_q(j,i));
    end
    nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
%%coeff 8bit zp
fileID = fopen('coeff_8bit_zp.txt','w+');
for j=1:N_kernel
    for i=1:10
        nbytes = fprintf(fileID,'%d,%d,',mu_zp,sigma_zp);
    end
    nbytes = fprintf(fileID,'\n');
end


% ----- RVFL ----- %

% azzero le variabili seguenti:
H=zeros(N_train,N_kernel); % hidden matrix usata nel training
H_test=zeros(N_test,N_kernel); % hidden matrix usata nel test

% inizializzazione a zero:
Y_train = zeros(N_train,N_class);
Y_test = zeros(N_test,N_class);

for k=1:N_class
    for i=1:N_train
        if Mat_train_tensor(i,11) == k
            Y_train(i,k) = 1;
        end
    end
end

for k=1:N_class
    for i=1:N_test
        if Mat_test_tensor(i,11) == k
            Y_test(i,k) = 1;
        end
    end
end
%%%%%%%%%%% Fase di Training %%%%%%%%%%%%
for ii=1:N_train % righe (training set)
    for jj=1:N_kernel % numero di trasformazioni non-lineari dell'input
        % distanza euclidea normalizzata per la funzione "h":
        H(ii,jj) = function_1_mod(Mat_train_tensor(ii,1:10),mu(jj,:),sigma(jj,:)); 
        Hq(ii,jj) = function_VHDL_mod(Mat_train_tensor(ii,1:10).*100,mu(jj,:).*100,sigma(jj,:).*100); 
        Hq8(ii,jj) = function_VHDL_mod(Mat_train_tensor(ii,1:10).*128,mu_q(jj,:)-mu_zp,sigma_q(jj,:)-sigma_zp); 
    end
end
Hq = double(Hq);
Hq8 = double(Hq8);
I = eye(N_kernel); % matrice identità quadrata
% inizializzo una matrice beta
beta = zeros(N_kernel,N_class);
beta_q = zeros(N_kernel,N_class);
beta_q8 = zeros(N_kernel,N_class);
% definisco la matrice beta secondo quanto dato dalla teoria:
beta = ((inv((H.')*H + lambda*I))*(H.')*(Y_train))*1000000;
beta_q = round(((inv((Hq.')*Hq + lambda*I))*(Hq.')*(Y_train))*1000000);
beta_q8 = ((inv((Hq8.')*Hq8 + lambda*I))*(Hq8.')*(Y_train));
[beta_q8, beta_q8_zp] = Q8(beta_q8,1);

%------------beta
fileID = fopen('coeff_beta.txt','w+');
for i=1:N_class
   for j=1:N_kernel
        nbytes = fprintf(fileID,'%d,',beta_q(j,i));
   end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
        
%------------beta_q8
fileID = fopen('coeff_beta_q8.txt','w+');
for i=1:N_class
   for j=1:N_kernel
        nbytes = fprintf(fileID,'%d,',beta_q8(j,i));
   end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);  

%------------beta_q8_zp
%{
fileID = fopen('coeff_beta_q8_zp.txt','w+');
for i=1:N_class
   for j=1:N_kernel
        nbytes = fprintf(fileID,'%d,',beta_q8_zp(j,i));
   end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);        
%}
        
beta_q8 = double(beta_q8);
beta_q8_zp = double(beta_q8_zp);
        
%-----------input
fileID = fopen('input.txt','w+');
for i=1:N_test
    for j=1:10
        nbytes = fprintf(fileID,'%d',floor(Mat_test_tensor(i,j,1).*100));
        nbytes = fprintf(fileID,'\n');
    end
end
fclose(fileID);

%-----------input
fileID = fopen('input_q8.txt','w+');
for i=1:N_test
    for j=1:10
        nbytes = fprintf(fileID,'%d',floor(Mat_test_tensor(i,j,1).*128));
        nbytes = fprintf(fileID,'\n');
    end
end
fclose(fileID);
        
%--------------
% definisco, analogamente al training, una matrice "H_test" 
for i=1:N_test
    for j=1:N_kernel
        H_test(i,j) = function_1_mod(Mat_test_tensor(i,1:10),mu(j,:),sigma(j,:)); 
        H_q_test(i,j) = function_VHDL_mod(Mat_test_tensor(i,1:10).*100,mu(j,:).*100,sigma(j,:).*100); 
        H_q8_test(i,j) = function_VHDL_mod(Mat_test_tensor(i,1:10).*128,mu_q(jj,:)-mu_zp,sigma_q(jj,:)-sigma_zp); 
    end
end

%---------H_Q
fileID = fopen('H_q_test.txt','w+');
for i=1:N_test
    for j=1:N_kernel
        nbytes = fprintf(fileID,'%d,',H_q_test(i,j));
    end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
%---------H_Q
fileID = fopen('H_q8_test.txt','w+');
for i=1:N_test
    for j=1:N_kernel
        nbytes = fprintf(fileID,'%d,',H_q8_test(i,j));
    end
        nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
%---------
H_q_test = double(H_q_test);
H_q8_test = double(H_q8_test);

for j=1:N_test
    for i=1:N_kernel
        YY_app(i,:) = beta(i,:)*H_test(j,i); % YY_app = variabile di appoggio, 
        YY_q_app(i,:) = fix(beta_q(i,:)*H_q_test(j,i)/1024);
        YY_q8_app(i,:) = fix((beta_q8(i,:)-beta_q8_zp)*H_q8_test(j,i)/1024);
        % per la quale poi sommo le componenti nel vettore YY_b
    end
    YY_b(j,:) = sum(YY_app,1);      
    YY_q_b(j,:) = sum(YY_q_app,1);
    YY_q8_b(j,:) = sum(YY_q8_app,1);
end
        
%----------CLASS
fileID = fopen('Class.txt','w+');
for j=1:N_test
    for i=1:N_class
        nbytes = fprintf(fileID,'%d,',YY_q_b(j,i));
    end
    nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
%---------------------------

%----------CLASS
fileID = fopen('Class_q8.txt','w+');
for j=1:N_test
    for i=1:N_class
        nbytes = fprintf(fileID,'%d,',YY_q8_b(j,i));
    end
    nbytes = fprintf(fileID,'\n');
end
fclose(fileID);
%---------------------------

% calcolo la posizione dell'indice che contiene il valore massimo
for i=1:N_test
    [~,idx] = max(YY_b(i,:));
    y_pred(i) = idx;
    [~,idx] = max(YY_q_b(i,:));
    y_pred_q(i) = idx;
    [~,idx] = max(YY_q8_b(i,:));
    y_pred_q8(i) = idx;
end

%%% Calcolo dell'accuratezza:
c = Mat_test_tensor(:,11) == y_pred;
f = sum(c);   
accuracy_vector = f / length(c);
cq = Mat_test_tensor(:,11) == y_pred_q;
fq = sum(cq);
accuracy_vector_q = fq / length(cq);
cq8 = Mat_test_tensor(:,11) == y_pred_q8;
fq8 = sum(cq8);
accuracy_vector_q8 = fq8 / length(cq8);


disp("done");
global_accuracy = [accuracy_vector accuracy_vector_q]


    

fileID = fopen('output_matlab.txt','w+');
for i=1:N_test
    nbytes = fprintf(fileID,'%d \n',y_pred_q(i));
end
fclose(fileID);


num_coef = size(mu,1)*size(mu,2) + size(sigma,1) * size(sigma,2) + size(beta_q,1)*size(beta_q,2);
fprintf('Numero di coefficienti in DATA MEMORY %d \n', num_coef); 
bits = num_coef*16;
fprintf('Occupazione memoria %d b - %d Kb - %d KB \n', bits, ceil(bits/1000), ceil(bits/8000)); 






    
    
