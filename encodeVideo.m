function encodeVideo( in_filename )
%Encodes a video using the block matching algorithm in ebma.m
    R = 32;
    
    %JPEG standard quantization matrix
    q = [   16  11  10  16  24  40  51  61; 
            12  12  14  19  26  58  60  55; 
            14  13  16  24  40  57  69  56; 
            14  17  22  29  51  87  80  62; 
            18  22  37  56  68 109 103  77; 
            24  35  55  64  81 104 113  92; 
            49  64  78  87 103 121 120 101; 
            72  92  95  98 112 100 103  99]; 
    
    if nargin < 1
        in_filename = 'flower.mpg'; 
    end
    v = VideoReader(in_filename);
    i = 1;
    while hasFrame(v)
        frame = readFrame(v);
        for j = 1:3
        % IBBPBBP is used in textbook notes, may be worth considering
            switch(i) %IBPBPBIBPBPB...
                case 1
                    %I frame comes in and is run through DCT
                    %It is then Quantized and sent to VLC
                    frame_q(:,:,j) = blkproc(double(frame(:,:,j)),[8,8],'round(dct2(x)./P1).*P1',q);
                    %push frame to output(From VLC)

                    %encoded to drop a lot of 0 bits, however, encoding of
                    %preceeding zeroes needs to be encoded for the reverse
                    %process in the decoder

                    if exist('bFrame','var')
                       processBFrame(bFrame(:,:,j), anchorFrame(:,:,j), frame(:,:,j), q, R); 
                    end
                    %Save I frame becomes anchor
                    anchorFrame(:,:,j) = frame(:,:,j);
                case 2
                    %B frame saved for future processing
                    bFrame(:,:,j) = frame(:,:,j);
                case 3
                    [motion(:,:,j),frame(:,:,j)] = ebma(anchorFrame(:,:,j), frame(:,:,j), R);
                    %push frame to output
                    %DCT and Quantization
                    frame_q(:,:,j) = blkproc(double(frame(:,:,j)),[8,8],'round(dct2(x)./P1).*P1',q);
                    processBFrame(bFrame(:,:,j), anchorFrame(:,:,j), frame(:,:,j), q, R);
                    %P frame becomes new anchor
                    anchorFrame(:,:,j) = frame(:,:,j);
                case 4
                    %B frame saved for future processing
                    bFrame(:,:,j) = frame(:,:,j);
                case 5
                    [motion(:,:,j),frame(:,:,j)] = ebma(anchorFrame(:,:,j), frame(:,:,j), R);
                    %push frame to output
                    %DCT and Quantization
                    frame_q(:,:,j) = blkproc(double(frame(:,:,j)),[8,8],'round(dct2(x)./P1).*P1',q);
                    processBFrame(bFrame(:,:,j), anchorFrame(:,:,j), frame(:,:,j), q, R);
                    %P frame becomes new anchor
                    anchorFrame(:,:,j) = frame(:,:,j);
                case 6
                    %B frame saved
                    %Might be good idea to end on a P frame so the next is I
                    %and previous processing can be ignored
                    bFrame(:,:,j) = frame(:,:,j);
            end
        end
        if i < 6
            i = i + 1;
        else
            i = 1;
        end
    end
end

function processBFrame(bFrame, bAnchor, aAnchor, q, R)
    [bmotion,bPredicted] = ebma(bAnchor, bFrame, R);
    [amotion,aPredicted] = ebma(aAnchor, bFrame, R);
    frame = (aPredicted + bPredicted)/2;
    motion = (amotion + bmotion)/2;
    %push frame to output
    %DCT and Quantization
    frame_q = blkproc(double(frame),[8,8],'round(dct2(x)./P1).*P1',q);
end