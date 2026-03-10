function a = generate_filter_for_random_pulses(M, ka)
    
    nfit = round(M/1.5);  % Lambda from the paper, length of correlation in the filter coefficients
    syms gx;  % Frequency variable omega
    syms y;   % cosine basis number
    
    % We shall write the target function in a way that automatically cancels
    % the two sinc parts in the target function and the numnerator of the
    % integral. This also avoids the problem of division by zero
    T = cos(ka*gx);  % Target window function 
    expr = T * cos(y*gx)*M/(M-y);

    intv = int(expr, gx, [-pi, pi]);  % Symbolic integration from -pi to pi (Why -pi to pi?)

    % Computing the Fourier cosine coefficients 
    coef = zeros(1, nfit);
    for i = 1:nfit
        if i ~= M
            coef(i) = double(subs(intv, y, i));
        else
            % Use symbolic limit to handle the singularity
            coef(i) = double(limit(intv, y, i));
        end
    end


    qm = ones(1, 2*nfit);
    c = 0.0025;
    
    % Finding maximum c such that q(m) > 0
    while qm > 0 
        qm = ones(1, 2*nfit);   % Power spectrum; twice as large an array as the filter coefficients
        c = c + 0.0025;
        for i = 1:2*nfit
            for k = 1:nfit
                qm(i) = qm(i) + 2 * sin(c*coef(k)) * cos(2*pi*k*i/(2*nfit));  % From Equation (C16)
            end
        end
    end

    c = 0.9*c;  % Ensures positivity

    % Construct the autocorrelation matrix
    n = nfit;
    for k = 1:n-1
        A{k} = [zeros(k , n-k), zeros(k, k); eye(n-k), zeros(n-k, k)];
    end

    manifold = spherefactory(n);
    problem.M = manifold;

    f = @(x) 0;  % Cost function, difference between the LHS and RHS of equation (C17)
    g = @(x) 0;  % Gradient of the cost function

    for i = 1:nfit-1
        f = @(x) f(x) + (asin(x'*A{i}*x) - c*coef(i))^2;
        g = @(x) g(x) + 2*(A{i}+A{i}')*x*asin(x'*A{i}*x)/sqrt(1 - (x'*A{i}*x)^2) ...
            - 2*c*coef(i)*(A{i}+A{i}')*x/sqrt(1 - (x'*A{i}*x)^2);
    end

    % Assign the cost and gradient to the problem structure
    problem.cost = @(x) f(x);
    problem.egrad = @(x) g(x);

    checkgradient(problem);
    options.tolgradnorm = 1.0e-15;

    [x, xcost, info, options] = trustregions(problem); 
    a = x'; % Stroing FIR coefficients as a row vector

end