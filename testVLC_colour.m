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

frm = imread('fruits.tif');

for i = 1:3
    frm_q(:,:,i) = blkproc(frm(:,:,i),[8,8],'round(dct2(x)./P1).*P1',q);
end
%output data
fileName = 'encodeTest.bin';
%create empty file for appending
f = fopen(fileName, 'w');
fclose(f);

zz = @(block_struct) writeFrame(block_struct.data, fileName);

for i = 1:3
    blockproc(frm_q(:,:,i), [8,8], zz);
end

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
% reconstruct DCT coefficient for the block
i = 1;
offset = 0;
frame = [];
for l = 1:64
    frameRow = [];
    for k = 1:64
        flag = 0;
        firstZero = 0;
        j = 1;
        blockVector = zeros(1,64);
        while flag ~= 1
            if (readData(i) == 0)
                if (firstZero == 1)
                    flag = 1;
                    i = i +1;
                else
                    firstZero = 1;
                    offset = i;
                    i = i + 1;
                end
            else
                if ( mod(i+offset,2) == 0)
                    j = j + readData(i);
                    i = i + 1;
                else
                    blockVector(j) = readData(i);
                    i = i + 1;
                    j = j + 1;
                end
            end
        end

        block = izigzag(blockVector,8,8);
        frameRow = [frameRow, block];
    end
    frame = [frame; frameRow];
end

%blockproc appear to do tl corner, tr, br, then continues on top row

function writeFrame(data, File_Name) 
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