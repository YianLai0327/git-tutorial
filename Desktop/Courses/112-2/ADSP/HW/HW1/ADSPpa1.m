N = 17;
k = (N - 1) / 2;
fs = 6000;
delta = 0.0001;
f = 0:delta:0.5;
border_l = 1200/fs;
border_r = 1500/fs;
W = 1*(f < border_l) + 0.6*(f > border_r);
thres = 1350/fs;

%Setup
A = zeros(k+2);
S = zeros(k+2, 1);
H = zeros(k+2, 1);
H_d = 1*(f < thres);
err_rem = [];

%Step 1
F = [0 0.07 0.12 0.15 0.17 0.28 0.33 0.38 0.45 0.5];
E_1 = Inf;
E_0 = 0;

while(E_1-E_0 > delta || E_1-E_0 < 0)
    %Step 2
    for i = 1:k+2
        A(i, 1:k+1) = cos(2*pi*(0:k)*F(i));
    end
    A(:, k+2) = (-1).^(0:k+1)./W(int32(F(:)/delta + 1));
    if det(A)==0
        display(det(A))
        return
    end
    S = A\(H_d(int32(F(:)/delta + 1)))';

    %Step 3
    R_F = zeros(1, length(f));
    for i = 1:k+1
        R_F = R_F + S(i)*cos(2*pi*(i-1)*f);
    end
    err = (R_F - H_d).*W;

    %Step 4
    %Check Peaks
    [~, indexes] = findpeaks(abs(err));
    index_1 = indexes;
    index_2 = indexes;
    index_1(index_1 > 2000) = 0;
    index_2(index_2 <= 2500) = 0;
    indexes = index_1 + index_2;
    indexes(indexes == 0) = [];
    
    %Check Boundary
    if (err(1) > 0 && err(2) < err(1)) || (err(1) < 0 && err(1) < err(2))
        indexes  = [indexes 1];
    elseif (err(5001) > 0 && err(5000) < err(5001)) || (err(5001) < 0 && err(5001) < err(5000))
        indexes = [indexes 5001];
    end

    [~, sorted_indexes] = sort(abs(err(indexes)), 'descend');
    indexes = indexes(sorted_indexes); 
    F(1:length(indexes)) = (indexes -1)*delta;
    F = sort(F);

    %Step 5
    E_1 = E_0;
    E_0 = max(abs(err));
    err_rem = [err_rem E_0];
end

% STEP 06
h(k+1) = S(0+1);
for i = 1:k
    h(k+i+1) = S(i+1)/2;
    h(k-i+1) = S(i+1)/2;
end

% Plot Frequency Response
subplot(211)
plot(f, R_F,'k',f ,H_d,'b')
title('Frequency Response');
xlabel('frequency(Hz)');
x = 0:16;

% Plot Impulse Response
subplot(212)
stem(x,h)
title('Impulse Response');
xlabel('time');
xlim([-1 18])

