v = VideoReader('/Users/timmytimmyliu/research/maap/videos/50V_3.avi');
vWidth = v.Width;
vHeight = v.Height;
%rect = [730, 550, 70, 30];
%rect = [600, 500, 70, 30];
rect = find_rect(v, 'template.png'); % put appropriate template here
originalFrame = rgb2gray(readFrame(v));
k = 1;
while v.hasFrame 
    frame = readFrame(v);
    frame = rgb2gray(frame); 
    mov(k).cdata = frame;
    k = k + 1;
end
template = imcrop(originalFrame, rect);
img = mov(21).cdata;
displacement = 50;
xtemp = rect(1);
ytemp = rect(2);
precision = rand; 
res = rand; 
tic
[xoffSet, yoffSet, dispx,dispy,x, y, c1, orig_interp2_time] = meas_displacement(template, rect, img, xtemp, ytemp, precision, displacement, res);
orig_disp_time = toc;

tic
[xoffSet1, yoffSet1, dispx1,dispy1,x1, y1, c11, new_interp2_time] = meas_displacement2(template, rect, img, xtemp, ytemp, precision, displacement, res);
new_disp_time = toc;


times = [orig_interp2_time new_interp2_time orig_disp_time new_disp_time];
%dlmwrite('normxcorr2_times.dat', times, '-append');
%dlmwrite('fourier_xc_times.dat', times, '-append');

% Notes:
%   - normxcorr2 cols: [orig_interp2_time new_interp2_time orig_disp_time new_disp_time]
%   - fourier_xc cols: [normxcorr_time fourier_xc_time orig_disp_time new_disp_time]
%       fourier_xc also takes takes in interp2 and qinterp2 times
%
%   - normxcorr2 averages: [0.00165434, 0.0017847793333333334, 0.021319013333333338, 0.018772909999999997]
%
%   - fourier_xc averages: [0.010571056666666667, 0.008897223333333334, 0.13102506666666666, 0.12615038333333334]



xoffSet == xoffSet1
yoffSet == yoffSet1
dispx == dispx1
dispy == dispy1
x1 == x
y == y1
c1 == c11 



