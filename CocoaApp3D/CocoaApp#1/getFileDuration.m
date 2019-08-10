//
//  getFileDuration.m
//  CocoaApp#1
//
//  Created by Sean Smith on 7/8/19.
//  Copyright © 2019 Sean Smith. All rights reserved.
//

#include "CocoaApp#1-Bridging-Header.h"

UInt32 getFileDuration(NSString *audioFilePath){
    NSURL *audioFileURL = [NSURL fileURLWithPath:audioFilePath];
    AudioFileID afid;
    
    //First open the file
    NSLog(@"Entered file duration function");
    OSStatus openAudioFileResult = AudioFileOpenURL((__bridge CFURLRef) audioFileURL, kAudioFileReadPermission, 0, &afid);
    NSLog(@"Next: Trying to open file");
    //Close the program if opening the file fails
    if(0 != openAudioFileResult){
        NSLog(@"An error occurred when attempting to open file %@: %ld", audioFilePath, (long) openAudioFileResult);
        return 0;
    }
    
    //ASBD will extract header data from audio file
    AudioStreamBasicDescription dataFormat;
    UInt32 propSize = sizeof(dataFormat);
    openAudioFileResult = AudioFileGetProperty(afid, kAudioFilePropertyDataFormat, &propSize, &dataFormat);
    
    //let us know if property fails
    if(0 != openAudioFileResult){
        NSLog(@"An error occurred when attempting to get the audio file properties %@: %ld", audioFilePath, (long) openAudioFileResult);
        return 0;
    }
    //the next three lines are purely feedback and can be commented out once the function is debugged
    NSLog(@"The number of bits per sample is %u", dataFormat.mBitsPerChannel);
    NSLog(@"The number of channels per frame is %u", dataFormat.mChannelsPerFrame);
    NSLog(@"The sample rate is %f", dataFormat.mSampleRate);
    
    UInt64 audioDataByteCount = 0;
    UInt32 propertySize = sizeof(audioDataByteCount);
    OSStatus getSizeResult = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &propertySize, &audioDataByteCount);
    
    if(0 != getSizeResult){
        NSLog(@"An error occurred when attempting to determine size of audio file %@: %ld", audioFilePath, (long) openAudioFileResult);
        return 0;
    }
    
    //Show byte count. Can be commented out later
    NSLog(@"The byte count is %llu: ", audioDataByteCount);
    //Calculate duration
    UInt32 fileLengthInSeconds = audioDataByteCount / (dataFormat.mSampleRate * dataFormat.mChannelsPerFrame * (dataFormat.mBitsPerChannel / 8));
    
    return fileLengthInSeconds;
}
