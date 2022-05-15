

% Funzione "h" con distanza euclidea normalizzata (distanza Mahalanobis)
% dove:
% inputArg1 = Mat_train(i,1:10) --->  %singolo vettore di features
% inputArg2 = mu(j,:) ---> %singola riga della matrice mu
% inputArg3 = sigma(j,:) ---> %singola riga della matrice sigma
% in pratica nel codice ci sarà (esempio):
% H(i,j) = function_1(Mat_train(i,1:10),mu(j,:),sigma(j,:));

function [outputArg1] = function_1(inputArg1,inputArg2,inputArg3)
%UNTITLED Summary of this function goes here
outputArg1 = sum(exp((-(inputArg1-inputArg2).^2)./(inputArg3).^2));
end



