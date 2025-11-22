k = input('Input k: ');
discrete_hilbert_trans(k);
function discrete_hilbert_trans(k)
    N = 2*k + 1;
    Hd = [-1i*ones(1, k) 1i*ones(1, k) 0];
    r = zeros(1, N);
  
    for j = 1:N
        r(j) = (1/N)*sum(Hd.*exp(1i*j*2*pi*(1:N)/N));
    end
    r = [r(k+1:N) r(1:k)];
    % Draw r[n], h[n]
    figure(1);
    % Plot r[n]
    subplot(211);
    stem(-k:k, real(r))
    title('r[n]');
    xlim([-k k]);
    ylim([-0.7 0.7]);
    % Plot h[n], shift with r[n]
    subplot(212);
    stem(0:(N-1), real(r));
    title('h[n]');
    xlim([0 2*k]);
    ylim([-0.7 0.7]);
    f = 1/N:(1/N):1;
    f_ = 1/(100*N):1/(N*100):1;
    R = zeros(1, length(f_));
    for j = -k:k
        R = R+ r(j+k+1)*exp(-1i*2*pi*j*f_);
    end

    figure(2)
    plot(...
    f, imag(Hd), 'black o',...
    f, imag(Hd), 'blue',...
    f_, imag(R), 'red'...
    );
    title('Frequency Response');
    xlabel('frequency(Hz)');
    ylim([-1.3 1.3])
end