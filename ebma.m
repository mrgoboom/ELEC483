function [motionVectors, predictedFrame] = ebma(anchor, target, R)
    % Referenced psuedo code at: http://s16.postimg.org/mgysv37ur/EBMA_pseudocode.jpg
    %R = 32; % window size +/- R
    N = 16; % block size NxN   

    % Read in frames
    %anchorFrame = imread(anchor);
    %targetFrame = imread(target);
    anchorFrame = anchor;
    targetFrame = target;
    
    % Get image dimensions
    [height, width] = size(anchorFrame);
    
    predictedFrame = zeros(height, width, 'uint8');
    x = zeros(height/N, width/N);
    y = zeros(height/N, width/N);
    u = zeros(height/N, width/N);
    v = zeros(height/N, width/N);
    
    %Block Loops
    for i = 1:N:height-N+1 % Loop through row of blocks
        for j = 1:N:width-N+1 % Loop through cols of blocks
            minMAD = 256*N*N; % Starting Value to compare with
            for k = -R:1:R % search candidate row location
                for l = -R:1:R % search candidate col location
                    %check for window going off edges of frame
                    if(i+k > 0)&&(i+k+N-1 < height)&&(j+l > 0)&&(j+l+N-1 < width)
                        % Calculate MAD for candidate
                        ancr = anchorFrame(i:i+N-1,j:j+N-1,1);
                        tgt = targetFrame(i+k:i+k+N-1,j+l:j+l+N-1,1);
                        MAD = sum(sum(abs(double(ancr) - double(tgt))));
                        %MAD = sum(sum(abs(anchorFrame(i:i+N-1,j:j+N-1,1)-targetFrame(i+k:i+k+N-1,j+l:j+l+N-1,1))));
                        if MAD < minMAD
                            minMAD = MAD;
                            dy = k;
                            dx = l;
                        end
                    end
                end
            end
            % build prediction from best matching block
            predictedFrame(i:i+N-1,j:j+N-1,1) = targetFrame(i+dy:i+dy+N-1,j+dx:j+dx+N-1,1);
            % build out motion vector matrices
            iblk = floor((i-1)/N+1);
            jblk = floor((j-1)/N+1);

            x(iblk, jblk) = j;
            y(iblk, jblk) = i;
            u(iblk, jblk) = dx;
            v(iblk, jblk) = dy;
        end
    end
    
    motionVectors = [x, y, u, v];
    
end