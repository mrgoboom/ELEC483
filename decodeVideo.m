function [decodedFrame] = decodeVideo( encodedFrame, video_writer, frameType, anchorFrame, motionVectors )
    %Run Inverse DCT on each frame and construct video file
    %This is just a skeleton of the process, will need correct syntax for
    %indexing through every frame of the encoded file
    
    if nargin < 3
        frameType = 'I';
    end
    
    switch(frameType)
        case 'I'
            %IDCT I frame
            for j = 1:3
                decodedFrame(:,:,j) = blkproc(encodedFrame(:,:,j),[8,8],'idct2');
            end
        case 'P'
            %Decode P frame
            if (exist('anchorFrame', 'var') && exist('motionVectors', 'var'))
                %IDCT error frame
                for j = 1:3
                    errorFrame(:,:,j) = blkproc(encodedFrame(:,:,j),[8,8],'idct2');
                end
%                 %IDCT anchor frame
%                 for j = 1:3
%                     anchor(:,:,j) = blkproc(anchorFrame(:,:,j),[8,8],'idct2');
%                 end
                %Rebuild the P frame
                for j = 1:3
                    decodedFrame(:,:,j) = rebuild(anchorFrame(:,:,j), errorFrame(:,:,j), motionVectors(:,:,j));
                end
            else
                error('Need Anchor and Motion Vector arguments for P frame');
            end            
        case 'B'
            %Decode B frame
            if (exist('anchorFrame', 'var') && exist('motionVectors', 'var'))
                %IDCT error frame
                for j = 1:3
                    errorFrame(:,:,j) = blkproc(encodedFrame(:,:,j),[8,8],'idct2');
                end
%                 %IDCT anchor frame
%                 for j = 1:3
%                     anchor(:,:,j) = blkproc(anchorFrame(:,:,j),[8,8],'idct2');
%                 end
                %Rebuild the B Frame
                for j = 1:3
                    decodedFrame(:,:,j) = rebuild(anchorFrame(:,:,j), errorFrame(:,:,j), motionVectors(:,:,j));
                end
            else
                error('Need Anchor and Motion Vector arguments for P frame');
            end
    end
    %debug code
    %figure;
    %imshow(uint8(decodedFrame))
    %open video for writing
    %open(video_writer);
    %write frame to video file
    writeVideo(video_writer,uint8(decodedFrame));
    %close the video file
    %close(video_writer);
    
end

function [reconstructedFrame] = rebuild(anchor, error, motion)
    % Read in frames
    N = 16; % NxN block size
    % Get image dimensions
    [height, width] = size(anchor);
    
    [rows, cols] = size(motion);
    predictedFrame = zeros(height, width);
    
    x = motion(:,1:floor(cols/4));
    y = motion(:,(floor(cols/4)+1):floor(cols/2));
    u = motion(:,(floor(cols/2)+1):floor(cols/4)*3);
    v = motion(:,((floor(cols/4)*3)+1):cols);

    %Block Loops
    for i = 1:rows % Loop through row of blocks
        for j = 1:floor(cols/4) % Loop through cols of blocks
            m = floor(y(i,j) + v(i,j));
            n = floor(x(i,j) + u(i,j));
            predictedFrame(y(i,j):y(i,j)+N-1,x(i,j):x(i,j)+N-1) = anchor(m:m+N-1,n:n+N-1);
        end
    end
    %Adjust for error
    reconstructedFrame = double(predictedFrame) + double(error);
end