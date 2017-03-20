function decodeVideo( encodedFrames )
    %Run Inverse DCT on each frame and construct video file
    %This is just a skeleton of the process, will need correct syntax for
    %indexing through every frame of the encoded file
    
    %Assuming the frame has been reconstructed i.e. not VLC needing motion
    %vectors for reconstruction etc.
    
    %IDCT
    decodedFrame = blkproc(encodedFrames,[8,8],'idct2');
    
    %create video writer object
    %lossless compression motion jpeg 2000 format
    decodedVideo = VideoWriter('decoded.mj2','Archival');
    
    %open video for writing
    open(decodedVideo);
    
    %write frame to video file
    writeVideo(decodedVideo,decodedFrame);
    
    %close the video file
    close(decodedVideo);
end