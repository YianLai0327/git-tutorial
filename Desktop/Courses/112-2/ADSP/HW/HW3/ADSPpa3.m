input = double(imread('input.jpg'));
out = C420(input);

% Plot the images
figure;
% Display original image
subplot(1, 2, 1);
imshow(uint8(input));
title('Original Image');

% Display output image (compressed and decompressed)
subplot(1, 2, 2);
imshow(out);
title('Reconstructed Image');

function out = C420(input)
    
    trans = [0.299 .587 .114 ; -0.169 -0.331 .5 ; .5 -0.419 -0.081 ];
    img_size = size(input);
    m = img_size(1)*img_size(2);
    RGB = reshape(input, m, 3);
    YCbCr = RGB*trans';
    img_YCbCr = reshape(YCbCr, img_size);

    Y = img_YCbCr(:, :, 1);
    Cb = img_YCbCr(:, :, 2);
    Cr = img_YCbCr(:, :, 3);
    
    Cb_sample = imresize(Cb, 0.5);
    Cr_sample = imresize(Cr, 0.5);

    %Y, Cb_sample, Cr_sample is the compressed form.

    %recovery

    Cb_recovery = upsample(upsample(Cb_sample,2)', 2)';
    Cr_recovery = upsample(upsample(Cr_sample,2)', 2)';

    for i = 1:ceil(img_size(1)/2 - 1)
        Cb_recovery(2*i, :) = (1/2) * (Cb_recovery(2*i-1, :) + Cb_recovery(2*i+1, :));
        Cr_recovery(2*i, :) = (1/2) * (Cr_recovery(2*i-1, :) + Cr_recovery(2*i+1, :));
    end

    for i = 1:ceil(img_size(2)/2 - 1)
        Cb_recovery(:, 2*i) = (1/2) * (Cb_recovery(:, 2*i-1) + Cb_recovery(:, 2*i+1));
        Cr_recovery(:, 2*i) = (1/2) * (Cr_recovery(:, 2*i-1) + Cr_recovery(:, 2*i+1));
    end

    if mod(img_size(1), 2) 
        Cb_recovery = Cb_recovery(1:end-1, :);
        Cr_recovery = Cr_recovery(1:end-1, :);
    else
        Cb_recovery(end, :) = Cb_recovery(end-1, :);
        Cr_recovery(end, :) = Cr_recovery(end-1, :);
    end    
    if mod(img_size(2), 2)
        Cb_recovery = Cb_recovery(:, 1:end-1);
        Cr_recovery = Cr_recovery(:, 1:end-1);
    else
        Cb_recovery(:, end) = Cb(:, end-1);
        Cr_recovery(:, end) = Cr(:, end-1);
    end

    YCbCr_recovery = zeros(img_size);
    YCbCr_recovery(:, :, 1) = Y;
    YCbCr_recovery(:, :, 2) = Cb_recovery;
    YCbCr_recovery(:, :, 3) = Cr_recovery;
    
    img_YCbCr_recovery = reshape(YCbCr_recovery, m, 3);
    RGB_recovery = img_YCbCr_recovery/trans';
    img_RGB_recovery = reshape(RGB_recovery, img_size);

    out = uint8(round(img_RGB_recovery));
end