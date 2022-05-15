function s = sigapproxVHDL(f_p)

    x = -5*f_p:0.001*f_p:5*f_p;
    sig = (1 ./(1+exp(-x./f_p)))*f_p;
    sa1 = 0.2*round(x) + 0.5*f_p;
    Intersections1=min(find(abs(sig-sa1)<=(0.005*f_p)));
    Intersections2=max(find(abs(sig-sa1)<=(0.005*f_p)));
    X_Values1 = round(x(Intersections1));
    Y_Values1 = round(sa1(Intersections1));
    X_Values2 = round(x(Intersections2));
    Y_Values2 = round(sa1(Intersections2));


    coefficients = polyfit([X_Values1, X_Values2], [Y_Values1,Y_Values2], 1);
    a = floor(log2(1/coefficients (1)));
    b = round(coefficients (2));
    coefficients2 = polyfit([-5*f_p, X_Values1], [0,Y_Values1], 1);
    a2 = floor(log2(1/coefficients2 (1)));
    b2 = round(coefficients2 (2));
    coefficients3 = polyfit([X_Values2, 5*f_p], [Y_Values2,1*f_p], 1);
    a3 = floor(log2(1/coefficients3 (1)));
    b3 = round(coefficients3 (2));
    
    r1 = bitshift(round(x),-a,'int16') + b;
    r2 = bitshift(round(x),-a2,'int16') + b2;
    r3 = bitshift(round(x),-a3,'int16') + b3;

    s = [f_p X_Values1 X_Values2 a b a2 b2 a3 b3];
    
    %{
    figure;
    plot(x,sig,'b');
    hold on;
    plot(x,r1,'y');
    hold on;
    plot(x,r2,'g');
    hold on;
    plot(x,r3,'r');
    hold off;
    %}
end