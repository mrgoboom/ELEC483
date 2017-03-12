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
        % IBBPBBP is used in textbook notes, may be worth considering
        switch(i) %IBPBPBIBPBPB...
            case 1
                %I frame comes in and is run through DCT
                %It is then Quantized and sent to VLC               
                frame_q = blkproc(double(frame),[8,8],'round(dct2(x)./P1).*P1',q);
                %push frame to output(From VLC)
                
                %encoded to drop a lot of 0 bits, however, encoding of
                %preceeding zeroes needs to be encoded for the reverse
                %process in the decoder
                
                if exist('bFrame','var')
                   processBFrame(bFrame, anchorFrame, frame, R); 
                end
                %Save I frame becomes anchor
                anchorFrame = frame;
            case 2
                %B frame saved for future processing
                bFrame = frame;
            case 3
                frame = ebma(anchorFrame, frame, R);
                %push frame to output
                %DCT and Quantization
                frame_q = blkproc(double(frame),[8,8],'round(dct2(x)./P1).*P1',q);
                processBFrame(bFrame, anchorFrame, frame, R);
                %P frame becomes new anchor
                anchorFrame = frame;
            case 4
                %B frame saved for future processing
                bFrame = frame;
            case 5
                frame = ebma(anchorFrame, frame, R);
                %push frame to output
                %DCT and Quantization
                frame_q = blkproc(double(frame),[8,8],'round(dct2(x)./P1).*P1',q);
                processBFrame(bFrame, anchorFrame, frame, R);
                %P frame becomes new anchor
                anchorFrame = frame;
            case 6
                %B frame saved
                %Might be good idea to end on a P frame so the next is I
                %and previous processing can be ignored
                bFrame = frame;
        end

        if i < 6
            i = i + 1;
        else
            i = 1;
        end
    end
end

function processBFrame(bFrame, bAnchor, aAnchor, R)
    bPredicted = ebma(bAnchor, bFrame, R);
    aPredicted = ebma(aAnchor, bFrame, R);
    frame = (aPredicted + bPredicted)/2;
    %push frame to output
    %DCT and Quantization
    frame_q = blkproc(double(frame),[8,8],'round(dct2(x)./P1).*P1',q);
end