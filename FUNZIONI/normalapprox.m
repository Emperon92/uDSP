
x = -3:0.001:3;
x1 = -3:0.001:-1.5;
x2 = -1.5:0.001:0;
x3 = 0:0.001:1.5;
x4 = 1.5:0.001:3;
sig = exp(-(x).^2);

r1 = 1/15.*x1+1/5;
r2 = 3/5.*x2+1;
r3 = -3/5.*x3+1;
r4 = -1/15.*x4+1/5;
    
 
figure;
plot(x,sig,'b');

hold on;
plot(x1,r1,'r');
hold on;
plot(x2,r2,'r');
hold on;
plot(x3,r3,'r');
hold on;
plot(x4,r4,'r');
xlabel('\alpha');
ylabel('Gaussian Distribution(\alpha)');
hold off;