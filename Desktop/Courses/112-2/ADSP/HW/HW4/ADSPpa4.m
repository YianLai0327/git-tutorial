L = 255;
c1 = 1/sqrt(L);
c2 = 1/sqrt(L);
img1 = double(imread("cat.png"));
img2 = double(imread("dog.png"));

img3 = img1*0.5 + 255*0.5;

ssim_12 = SSIM(img1, img2, c1, c2);
ssim_13 = SSIM(img1, img3, c1, c2);

disp("SSIM between img1 and img2: " + num2str(ssim_12))
disp("SSIM between img1 and img3: " + num2str(ssim_13))
if ssim_12 > ssim_13
    disp("img1, img2 are more alike.")

else
    disp("img1, img3 are more alike.")
end


function ssim = SSIM(A, B, c1, c2)
    L = 255;
    mu_x = mean(A, 'all');
    mu_y = mean(B, 'all');

    var_x = mean(A.^2, 'all') - mu_x^2;
    var_y = mean(B.^2, 'all') - mu_y^2;

    cov_xy = mean((A - mu_x).*(B - mu_y), 'all');

    ssim = (2*mu_x*mu_y + (c1*L)^2) * (2*cov_xy + (c2*L)^2) / ((mu_x^2 + mu_y^2 + (c1*L)^2)*(var_x + var_y + (c2*L)^2));
end