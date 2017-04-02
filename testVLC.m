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
%output data
fileName = 'encodeTest.bin';
%create empty file for appending
f = fopen(fileName, 'w');
fclose(f);

zz = @(block_struct) zigzagScan(block_struct.data, fileName);
blockproc(frm_q, [8,8], zz);

%read created file

fid = fopen(fileName);
k =0;
while ~feof(fid)
    current = fread(fid,1,'int16');
    if ~isempty(current)
        k = k+1;
        readData(k) = current;
    end
end

%blockproc appear to do tl corner, tr, br, then continues on top row

function zigzagScan(data, File_Name) 
    %http://stackoverflow.com/questions/3024939/matrix-zigzag-reordering
    ind = reshape(1:numel(data), size(data));
    ind = fliplr(spdiags(fliplr(ind)));
    ind(:,1:2:end) = flipud(ind(:,1:2:end));
    ind(ind==0) = [];

    coef = data(ind);
    encoded = coef(1); %DC Coefficient
    run = 0;
    for i = 2:numel(coef)
        if coef(i) == 0
            run = run + 1;
        else
            encoded = [encoded, run, coef(i)];
            run = 0;
        end
    end
    
    output = int16([encoded, 0, 0].'); %00 is EOB
    
    fileID = fopen(File_Name, 'a'); %append
    fwrite(fileID, output, 'int16');
    fclose(fileID);
end