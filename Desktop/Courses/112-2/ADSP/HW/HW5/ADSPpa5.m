% Test the FFT function fftreal
x = 1:10;
y = 11:20;
[XX, YY] = fftreal(x, y);
disp('X = '); disp(XX);
disp('Y = '); disp(YY);

function [X, Y] = fftreal(x, y)
      
    z = x + 1i * y;

    % Compute the FFT of the complex signal
    Z = fft(z);

    % Extract the FFT of x and y from Z
    N = length(Z);
    X = zeros(N, 1)';
    Y = zeros(N, 1)';
    X_r = zeros(N, 1)';
    Y_r = zeros(N, 1)';
    X_i = zeros(N, 1)';
    Y_i = zeros(N, 1)';

    X(1) = real(Z(1));
    Y(1) = imag(Z(1));

    half = ceil(N/2);
    for k = 2:half
        X_r(k) = real(Z(k)+Z(N+2-k))/2;
        X_i(k) = imag(Z(k)-Z(N+2-k))/2;
        Y_r(k) = imag(Z(k)+Z(N+2-k))/2;
        Y_i(k) = real(-Z(k)+Z(N+2-k))/2;
    end
    if mod(N, 2)==0
        X(N/2+1) = real(Z(N/2+1));
        Y(N/2+1) = imag(Z(N/2+1));
    end

    % Use symmetry properties for the second half of the FFT results
    X(2:half) = X_r(2:half) + 1i*X_i(2:half);
    Y(2:half) = Y_r(2:half) + 1i*Y_i(2:half);
    if mod(N, 2)==0
        X(half+2:end) = X_r(half:-1:2) - 1i*X_i(half:-1:2);
        Y(half+2:end) = Y_r(half:-1:2) - 1i*Y_i(half:-1:2);
    else
        X(half+1:end) = X_r(half:-1:2) - 1i*X_i(half:-1:2);
        Y(half+1:end) = Y_r(half:-1:2) - 1i*Y_i(half:-1:2);
    end
end