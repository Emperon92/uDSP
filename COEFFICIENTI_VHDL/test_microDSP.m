clear all;
clc;
close all;

fileID = fopen('output_matlab.txt','r');
A = fscanf(fileID,'%d');
fclose(fileID);

format longG;

fileID = fopen('output.txt','r');
B = fscanf(fileID,'%d');
fclose(fileID);
if (size(A) == size(B))
    C = A == B;
    cor = (sum(C)/length(C))*100;
    fprintf('La corrispondenza tra output_matlab e output_DSP è %d%%\n', cor); 
else 
    fprintf('I file di testo hanno diverse dimensioni'); 
end

ERR = find(C==0)