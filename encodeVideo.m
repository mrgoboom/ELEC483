function encodeVideo( in_filename )
%Encodes a video using the block matching algorithm in ebma.m
    R = 32;
    if nargin < 1
        in_filename = 'flower.mpg'; 
    end
    v = VideoReader(in_filename);
    i = 1;
    while hasFrame(v)
        frame = readFrame(v); 
        switch(i) %IBPBPBIBPBPB...
            case 1
                %push frame to output
                if exist('bFrame','var')
                   processBFrame(bFrame, anchorFrame, frame, R); 
                end
                anchorFrame = frame;
            case 2
                bFrame = frame;
            case 3
                frame = ebma(anchorFrame, frame, R);
                %push frame to output
                processBFrame(bFrame, anchorFrame, frame, R);
                anchorFrame = frame;
            case 4
                bFrame = frame;
            case 5
                frame = ebma(anchorFrame, frame, R);
                %push frame to output
                processBFrame(bFrame, anchorFrame, frame, R);
                anchorFrame = frame;
            case 6
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
end