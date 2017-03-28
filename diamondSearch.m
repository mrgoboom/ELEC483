function [motionVectors, predictedFrame] = diamondSearch(anchor, target, R)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    N = 16; % block size NxN

    if nargin < 3
        anchor = 'train01.tif';
        target = 'train02.tif';
        R = 7;
        % Read in frames
        anchorFrame = imread(anchor);
        targetFrame = imread(target);
    else
        anchorFrame = anchor;
        targetFrame = target;
    end
    
    % Get image dimensions
    [height, width] = size(anchorFrame);
    
    predictedFrame = zeros(height, width, 'uint8');
    x = zeros(height/N, width/N);
    y = zeros(height/N, width/N);
    u = zeros(height/N, width/N);
    v = zeros(height/N, width/N);
    
    % Block Loops
    for i=1:N:height-N+1 % Loop through row of blocks
        for j=1:N:width-N+1 % Loop through cols of blocks
            minMAD = 256*N*N; % Starting Value to compare with (will be beat)
            anchorBlock = createBlock(anchorFrame,i,j,N); %anchor block to compare to
            iLow = 0;
            iHigh = height-N+1;
            jLow = 0;
            jHigh = width-N+1;
            if(i-(R*N)>0)
               iLow = i-(R*N); 
            end
            if(j-(R*N)>0)
               jLow = j-(R*N);
            end
            if(i+(R*N)<iHigh)
               iHigh = i+(R*N); 
            end
            if(j+(R*N)<jHigh)
               jHigh = j+(R*N); 
            end
            ti=i;
            tj=j;
            targetBlock = createBlock(targetFrame,i,j,N);%centreBlock
            [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,0,1);
            not_found = true;
            %diamonds often include boxes from previous diamonds
            %already_checked allows us to ignore those boxes in next check
            already_checked = 1;
            while(not_found)
                if(ti-(2*N)>iLow && mod(already_checked,2)>0)%top block
                    targetBlock = createBlock(targetFrame,ti-(2*N),tj,N);
                    [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,2);
                end
                if(ti-N>iLow)
                   if(tj-N>jLow && mod(already_checked,3)>0)%top left block
                      targetBlock = createBlock(targetFrame,ti-N,tj-N,N);
                      [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,3);
                   end
                   if(tj+N<jHigh && mod(already_checked,5)>0)%top right block
                      targetBlock = createBlock(targetFrame,ti-N,tj+N,N);
                      [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,4);
                   end
                end
                if(tj-(2*N)>jLow && mod(already_checked,7)>0)%left block
                    targetBlock = createBlock(targetFrame,ti,tj-(2*N),N);
                    [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,5);
                end
                if(tj+(2*N)<jHigh && mod(already_checked,11)>0)%right block
                    targetBlock = createBlock(targetFrame,ti,tj+(2*N),N);
                    [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,6);
                end
                if(ti+N<iHigh)
                    if(tj-N>jLow && mod(already_checked,13)>0)%bottom left block
                        targetBlock = createBlock(targetFrame,ti+N,tj-N,N);
                        [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,7);
                    end
                    if(tj+N<jHigh && mod(already_checked,17)>0)%bottom right block
                        targetBlock = createBlock(targetFrame,ti+N,tj+N,N);
                        [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,8);
                    end
                end
                if(ti+(2*N)<iHigh && mod(already_checked,19)>0)%bottom block
                    targetBlock = createBlock(targetFrame,ti+(2*N),tj,N);
                    [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,9);
                end
                switch(index)
                %index represents the case with best match.
                %minMAD is the match of this block
                
                %case 1 indicates the middle is the best match and we move
                %to the next step
                %otherwise, set best match as middle and test new points
                    case 1
                        not_found = false;
                    case 2
                        ti = ti-(2*N);
                        already_checked = 19*17*13;
                        index = 1;
                    case 3
                        ti = ti-N;
                        tj = tj-N;
                        already_checked = 5*11*13*17*19;
                        index = 1;
                    case 4
                        ti = ti-N;
                        tj = tj+N;
                        already_checked = 3*7*13*17*19;
                        index = 1;
                    case 5
                        tj = tj-(2*N);
                        already_checked = 5*11*17;
                        index = 1;
                    case 6
                        tj = tj+(2*N);
                        already_checked = 3*7*13;
                        index = 1;
                    case 7
                        ti = ti+N;
                        tj = tj-N;
                        already_checked = 2*3*5*11*17;
                        index = 1;
                    case 8
                        ti = ti+N;
                        tj = tj+N;
                        already_checked = 2*3*5*7*13;
                        index = 1;
                    case 9
                        ti = ti+(2*N);
                        already_checked = 2*3*5;
                        index = 1;
                    otherwise
                        fprintf('Something has gone seriously wrong');
                        motionVectors = 0;
                        return
                end
            end
            %test 4 blocks in middle of diamond
            if(ti-N>iLow)%top block
                targetBlock = createBlock(targetFrame,ti-N,tj,N);
                [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,2);
            end
            if(tj-N>jLow)
                targetBlock = createBlock(targetFrame,ti,tj-N,N);
                [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,3);
            end
            if(tj+N<jHigh)
                targetBlock = createBlock(targetFrame,ti,tj+N,N);
                [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,4); 
            end
            if(ti+N<iHigh)
                targetBlock = createBlock(targetFrame,ti+N,tj,N);
                [minMAD, index] = testBlock(anchorBlock,targetBlock,minMAD,index,5); 
            end
            switch(index)
                %index represents the case with best match.
                %minMAD is the match of this block
                case 2
                    ti = ti-N;
                case 3
                    tj = tj-N;
                case 4
                    tj = tj+N;
                case 5
                    ti = ti+N;
                case 1
                    %do nothing
                otherwise
                    fprintf('Something has gone seriously wrong');
                    motionVectors = 0;
                    return
            end
            dx = (tj-j)/N;
            dy = (ti-i)/N;
            %build prediction from best matching block
            predictedFrame(i:i+N-1,j:j+N-1,1) = targetFrame(i+dy:i+dy+N-1,j+dx:j+dx+N-1,1);
            %build motion vector matrices
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

function block = createBlock(matrix, topLeft1, topLeft2, N)
    block = matrix(topLeft1:topLeft1+N-1,topLeft2:topLeft2+N-1);
end

% targetBlock is compared to anchorBlock
% If difference is less than minMAD, return difference and index
% If not, return old minMAD and mindex
function [minMAD, changed] = testBlock(anchorBlock, targetBlock, minMAD, mindex, index)
    MAD = sum(sum(abs(double(anchorBlock) - double(targetBlock))));
    changed = mindex;
    if MAD < minMAD
        minMAD = MAD;
        changed = index;
    end
end