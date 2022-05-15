function g = Cfl(input,exord)      %input vettore 10 features; expor ordine espansione                                                          
    c = 0;                                                                                          % Counter variable for the index of expanded vector
    for i = 1:length(input)                                                                                   % Read the input buffer untill Mi-th sample
        g1 = input(i);                                                                              % Initialization of the first past sample
        g2 = 1;                                                                                     % Initialization of the second past sample
        for j = 1:exord
            c = c + 1;
            %if c > Me, break, end
            g(c) = 2*input(i)*g1 - g2;                                                              % Compute the output sample
            g2 = g1;                                                                                % Shift memory
            g1 = g(c);                                                                              % Shift memory
        end
    end
end