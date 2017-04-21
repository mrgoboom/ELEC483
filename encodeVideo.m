function encodeVideo( in_filename )
%Encodes a video using the block matching algorithm in ebma.m
    tic;
    R = 8;
    
    %JPEG standard quantization matrix
    q = [   16  11  10  16  24  40  51  61; 
            12  12  14  19  26  58  60  55; 
            14  13  16  24  40  57  69  56; 
            14  17  22  29  51  87  80  62; 
            18  22  37  56  68 109 103  77; 
            24  35  55  64  81 104 113  92; 
            49  64  78  87 103 121 120 101; 
            72  92  95  98 112 100 103  99]; 
    %output data
    fileName = 'encodeOut.bin';
    %create empty file for appending
    f = fopen(fileName, 'w');
    fclose(f);
    
    decodedVideo = VideoWriter('decoded','Uncompressed AVI');
    open(decodedVideo);

    wframe = @(block_struct) writeFrame(block_struct.data, fileName);
    
    if nargin < 1
        in_filename = 'flower.mpg'; 
    end
    v = VideoReader(in_filename);
    i = 1;
    %algTime = [];
    while hasFrame(v)
        frame = readFrame(v);
        for j = 1:3
            switch(i) %IBPBPIBPBPI...
                case 1
                    %I frame comes in and is run through DCT
                    %push frame to output
                    frame_q(:,:,j) = blkproc(double(frame(:,:,j)),[8,8],'round(dct2(x)./P1).*P1',q);
                    blockproc(frame_q(:,:,j), [8,8], wframe);
                    %Save I frame becomes anchor
                    anchorFrame(:,:,j) = frame(:,:,j);
                case 2
                    %B frame saved for future processing
                    bFrame(:,:,j) = frame(:,:,j);
                case 3
                    %tic;
                    [motion(:,:,j),pframe] = diamondSearch(anchorFrame(:,:,j), frame(:,:,j), R);
                    %algTime = [algTime, toc];
                    error(:,:,j) = abs(double(pframe)-double(frame(:,:,j)));
                    %frame(:,:,j) = pframe;
                    %push frame to output
                    [errorb(:,:,j), motionb(:,:,j)] = processBFrame(bFrame(:,:,j), anchorFrame(:,:,j), pframe, q, R, fileName);
                    %DCT and Quantization
                    %write P frame error to file
                    frame_q(:,:,j) = blkproc(double(error(:,:,j)),[8,8],'round(dct2(x)./P1).*P1',q);
                    blockproc(frame_q(:,:,j), [8,8], wframe);
                    %write P frame motion vectors
                    fid = fopen(fileName, 'a');
                    fwrite(fid, uint16(motion(:,:,j)));
                    fclose(fid);
                    %P frame becomes new anchor
                    anchorFrame(:,:,j) = frame(:,:,j);
                case 4
                    %B frame saved for future processing
                    bFrame(:,:,j) = frame(:,:,j);
                case 5
                    %tic;
                    [motion(:,:,j),pframe] = diamondSearch(anchorFrame(:,:,j), frame(:,:,j), R);
                    %algTime = [algTime, toc];
                    error(:,:,j) = abs(double(pframe)-double(frame(:,:,j)));
                    frame(:,:,j) = pframe;
                    %push frame to output
                    [errorb(:,:,j), motionb(:,:,j)] = processBFrame(bFrame(:,:,j), anchorFrame(:,:,j), frame(:,:,j), q, R, fileName);
                    %DCT and Quantization
                    processBFrame(bFrame(:,:,j), anchorFrame(:,:,j), frame(:,:,j), q, R, fileName);
                    frame_q(:,:,j) = blkproc(double(error(:,:,j)),[8,8],'round(dct2(x)./P1).*P1',q);
                    blockproc(frame_q(:,:,j), [8,8], wframe);
                    %write P frame motion vectors
                    fid = fopen(fileName, 'a');
                    fwrite(fid, uint16(motion(:,:,j)));
                    fclose(fid);
                    %P frame becomes new anchor
                    anchorFrame(:,:,j) = frame(:,:,j);
            end
        end
        
        %Debug
        %figure;
        %imshow(frame)
        
        %Decoding and write to video file
        
        %create Video Writer
        
        switch(i) %IBPBPIBPBPI...
            case 1
                %I Frame
                anchor = decodeVideo(frame_q, decodedVideo, 'I'); 
                %anchor = frame_q;
            case 3
                %B Frame
                decodeVideo(errorb, decodedVideo, 'B', anchor, motionb);
                %P Frame
                anchor = decodeVideo(frame_q, decodedVideo, 'P', anchor, motion);
                %anchor = frame_q;
            case 5
                %B Frame
                decodeVideo(errorb, decodedVideo, 'B', anchor, motionb);
                %P Frame
                decodeVideo(frame_q, decodedVideo, 'P', anchor, motion);
        end
       
        if i < 5
            i = i + 1;
        else
            i = 1;
        end
    end
    close(decodedVideo);
    toc
    %mean(algTime)
end

function [frame_q, motion] = processBFrame(bFrame, bAnchor, aAnchor, q, R, file_name)
    [bmotion,bPredicted] = diamondSearch(bAnchor, bFrame, R);
    [amotion,aPredicted] = diamondSearch(aAnchor, bFrame, R);
    frame = (aPredicted + bPredicted)/2;
    error = abs(double(frame)-double(bFrame));
    motion = (amotion + bmotion)/2;
    %push frame to output
    wframe = @(block_struct) writeFrame(block_struct.data, file_name);
    %DCT and Quantization
    %write error frame
    frame_q = blkproc(double(error),[8,8],'round(dct2(x)./P1).*P1',q);
    blockproc(frame_q, [8,8], wframe);
    %write motion vectors
    fid = fopen(file_name, 'a');
    fwrite(fid, uint16(motion));
    fclose(fid);
end

% Used with blockproc to encode and write blocks of the frame to a file
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