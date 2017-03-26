clear;
clc;

q = [16  11  10  16  24  40  51  61; 
     12  12  14  19  26  58  60  55; 
     14  13  16  24  40  57  69  56; 
     14  17  22  29  51  87  80  62; 
     18  22  37  56  68 109 103  77; 
     24  35  55  64  81 104 113  92; 
     49  64  78  87 103 121 120 101; 
     72  92  95  98 112 100 103  99];

frm = imread('lena.tif');

frm_q = blkproc(frm,[8,8],'round(dct2(x)./P1).*P1',q);
zz = @(block_struct) zigzagScan(block_struct.data);
coef = blockproc(frm_q, [8,8], zz);

%ind = reshape(1:numel(frm_q), size(frm_q));
function [coef] = zigzagScan(data) 
    %http://stackoverflow.com/questions/3024939/matrix-zigzag-reordering
    ind = reshape(1:numel(data), size(data));
    ind = fliplr(spdiags(fliplr(ind)));
    ind(:,1:2:end) = flipud(ind(:,1:2:end));
    ind(ind==0) = [];

    coef = data(ind);
end