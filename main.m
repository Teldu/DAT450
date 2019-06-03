#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define SAMPLE_RATE 44100    // 1
// #define FILENAME_FORMAT @"%0.3f-square.aif"
// #define FILENAME_FORMAT @"%0.3f-saw.aif"
//#define FILENAME_FORMAT @"%0.3f-wave.aif"

int main (int argc, const char * argv[]) {
    char freqHz[10], lenSec[5]/*, ampRatio[5], numHarm[5]*/;
    char wave[20], fn[40];
    printf("Enter file name: ");
    scanf("%s", fn);
    printf ("Choose wave type \n1. Sine\n2. Square\n3. Triangle\n");
    printf ("4. Sawtooth\n5. Pulse\n");
    scanf ("%s", wave);
    printf("\nEnter Frequency in Hz: ");
    scanf ("%s", freqHz);
    printf ("\nEnter duration in seconds: ");
    scanf ("%s", lenSec);
    //printf("\nEnter amplitude ratio: ");
    //scanf ("%s", ampRatio);
    printf("\n\n\n");
    //printf("\nEnter number of harmonics: ");
    //scanf("%s", numHarm);
    
   /* if (argc < 2) {
        printf ("Usage: CAToneFileGenerator n\n(where n is tone in Hz)");
        return -1;
    } // 1*/
    
    double hz = atof(freqHz);    // 2
    double length = atof(lenSec);
    //double amp = atof(ampRatio);
    //double harmonics = atof(numHarm);
    assert (hz > 0);
    NSLog (@"generating %lf hz tone", hz);
    
    //NSString *fileName = [NSString stringWithFormat:FILENAME_FORMAT, hz];
    NSString *fileName = [NSString stringWithCString:fn encoding:1];
    NSString *filePath = [[[NSFileManager defaultManager] currentDirectoryPath]
                          stringByAppendingPathComponent: fileName];
    NSURL *fileURL = [NSURL fileURLWithPath: filePath];
    NSLog (@"path: %@", fileURL);
    
    // prepare the format
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    asbd.mSampleRate = SAMPLE_RATE;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mChannelsPerFrame = 1;
    asbd.mFramesPerPacket = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mBytesPerFrame = 2;
    asbd.mBytesPerPacket = 2;
    
    // set up the file
    AudioFileID audioFile;
    OSStatus audioErr = noErr;
    audioErr = AudioFileCreateWithURL((__bridge CFURLRef)fileURL,
                                      kAudioFileAIFFType,
                                      &asbd,
                                      kAudioFileFlags_EraseFile,
                                      &audioFile);
    assert (audioErr == noErr);
    
    // start writing samples
    long maxSampleCount = SAMPLE_RATE * length;
    long sampleCount = 0;
    UInt32 bytesToWrite = 2;
    double wavelengthInSamples = SAMPLE_RATE / hz;
    NSLog (@"wavelengthInSamples = %f", wavelengthInSamples);
    
    if(!strcmp("sine", wave)){
        while (sampleCount < maxSampleCount) {
            for (int i=0; i<wavelengthInSamples; i++) {
                // sine wave
                SInt16 sample = CFSwapInt16HostToBig ((SInt16) SHRT_MAX *
                                                      sin (2 * M_PI *
                                                           (i / wavelengthInSamples)));
                
                
                audioErr = AudioFileWriteBytes(audioFile,
                                               false,
                                               sampleCount*2,
                                               &bytesToWrite,
                                               &sample);
                assert (audioErr == noErr);
                sampleCount++;
            }
        }
    }
    else if(!strcmp("square", wave)){
        while (sampleCount < maxSampleCount) {
            for (int i=0; i<wavelengthInSamples; i++) {
                    SInt16 sample;
                    if (i < wavelengthInSamples/2) {
                        sample = CFSwapInt16HostToBig (SHRT_MAX);
                    } else {
                        sample = CFSwapInt16HostToBig (SHRT_MIN);
                    }
                    audioErr = AudioFileWriteBytes(audioFile,
                                                   false,
                                                   sampleCount*2,
                                                   &bytesToWrite,
                                                   &sample);
                    assert (audioErr == noErr);
            }
        }
    }
    else if(!strcmp("triangle", wave)){
        while (sampleCount < maxSampleCount) {
            for (int i=0; i<wavelengthInSamples; i++) {
                SInt16 sample = CFSwapInt16HostToBig ((SInt16) SHRT_MAX *
                                                      (0.5 * (sin (2 * M_PI * (i / wavelengthInSamples) * i)) +
                                                       (-1 * (sin (2 * M_PI * (i / wavelengthInSamples) * i * 3) / 9)) +
                                                       (sin (2 * M_PI * (i / wavelengthInSamples) * i * 5) / 25) +
                                                       (-1 * (sin (2 * M_PI * (i / wavelengthInSamples) * i * 7) / 49))
                                                       ));
                
                audioErr = AudioFileWriteBytes(audioFile,
                                               false,
                                               sampleCount*2,
                                               &bytesToWrite,
                                               &sample);
                assert (audioErr == noErr);
                sampleCount++;
            }
        }
    }
    else if(!strcmp("sawtooth", wave)){
        while (sampleCount < maxSampleCount) {
            for (int i=0; i<wavelengthInSamples; i++){
                SInt16 sample = CFSwapInt16HostToBig (((i / wavelengthInSamples) * SHRT_MAX *2) -
                                                      SHRT_MAX);
                audioErr = AudioFileWriteBytes(audioFile,
                                               false,
                                               sampleCount*2,
                                               &bytesToWrite,
                                               &sample);
                assert (audioErr == noErr);
                sampleCount++;
            }
        }
    }
    else if(!strcmp("pulse", wave)){
        while (sampleCount < maxSampleCount) {
            for (int i=0; i<wavelengthInSamples; i++) {
                SInt16 sample;
                if (i < wavelengthInSamples/2) {
                    sample = CFSwapInt16HostToBig (SHRT_MAX);
                } else {
                    sample = CFSwapInt16HostToBig (SHRT_MIN);
                }
                audioErr = AudioFileWriteBytes(audioFile,
                                               false,
                                               sampleCount*2,
                                               &bytesToWrite,
                                               &sample);
                assert (audioErr == noErr);
            }
        }
    }
    audioErr = AudioFileClose(audioFile);
    assert (audioErr == noErr);
    NSLog (@"wrote %ld samples", sampleCount);
    
    return 0;
}
