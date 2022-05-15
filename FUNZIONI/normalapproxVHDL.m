
x = -30000:1:30000;
x1 = -30000:1:-15000;
x2 = -15000:1:0;
x3 = 0:1:15000;
x4 = 15000:1:30000;
sig = 1000*exp(-(x/10000).^2);


r1 = -bitshift(-x1,-log2(128),'int16')+200;
r2 = -bitshift(-x2,-log2(16),'int16')+1000;
r3 = -bitshift(x3,-log2(16),'int16')+1000;
r4 = -bitshift(x4,-log2(128),'int16')+200;

 
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

