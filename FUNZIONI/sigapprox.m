function s = sigapprox(f_p)

    x = -5*f_p:0.001*f_p:5*f_p;
    sig = (1 ./(1+exp(-x./f_p)))*f_p;
    sa1 = 0.2*x + 0.5*f_p;
    Intersections1=min(find(abs(sig-sa1)<=(0.005*f_p)));
    Intersections2=max(find(abs(sig-sa1)<=(0.005*f_p)));
    X_Values1 = x(Intersections1);
    Y_Values1 = sa1(Intersections1);
    X_Values2 = x(Intersections2);
    Y_Values2 = sa1(Intersections2);


    coefficients = polyfit([X_Values1, X_Values2], [Y_Values1,Y_Values2], 1);
    a = coefficients (1);
    b = coefficients (2);
    coefficients2 = polyfit([-5*f_p, X_Values1], [0,Y_Values1], 1);
    a2 = coefficients2 (1);
    b2 = coefficients2 (2);
    coefficients3 = polyfit([X_Values2, 5*f_p], [Y_Values2,1*f_p], 1);
    a3 = coefficients3 (1);
    b3 = coefficients3 (2);
    
    r1 = a.*x+b;
    r2 = a2.*x+b2;
    r3 = a3.*x+b3;

    s = [f_p X_Values1 X_Values2 a b a2 b2 a3 b3];
    
    %{
    figure;
    plot(x,sig,'b');
    hold on;
    plot(x,r1,'r');
    hold on;
    plot(x,r2,'r');
    hold on;
    plot(x,r3,'r');
    hold off;
    %}
end