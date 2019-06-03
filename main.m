#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
//#include <string>
//#include <iostream>
//using namespace std;

#define SAMPLE_RATE 44100	// 1
// #define FILENAME_FORMAT @"%0.3f-square.aif"
// #define FILENAME_FORMAT @"%0.3f-saw.aif"
#define FILENAME_FORMAT @"%0.3f-wave.aif"

int main (int argc, const char * argv[]) {
  /*  double hz, length, amp, harmonics;
    string wave;
    cout << "Choose wave type \n1. Sine\n2. Square\n3. Triangle\n";
    cout << "4. Sawtooth\n5. Pulse " << endl;
    cin >> (getline, wave);
    cout << "Enter hz: " << endl;
    cin >> hz;
    cout << "Enter duration in seconds:" << endl;
    cin >> length;
    length *= SAMPLE_RATE;
    cout << "Enter amplitude: " << endl;
    cin >> amp;
    cout << "Enter number of harmonics: " << endl;
   */
    if (argc < 2) {
        printf ("Usage: CAToneFileGenerator n\n(where n is tone in Hz)");
        return -1;
    } // 1
    
    double hz = atof(argv[1]);    // 2
	assert (hz > 0);
	NSLog (@"generating %f hz tone", hz);
	
	NSString *fileName = [NSString stringWithFormat:FILENAME_FORMAT, hz];
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
	long maxSampleCount = SAMPLE_RATE * 5;
    //long maxSampleCount = SAMPLE_RATE * length;
	long sampleCount = 0;
	UInt32 bytesToWrite = 2;
	double wavelengthInSamples = SAMPLE_RATE / hz;
	NSLog (@"wavelengthInSamples = %f", wavelengthInSamples);
	
	while (sampleCount < maxSampleCount) {
		for (int i=0; i<wavelengthInSamples; i++) {
            if(/*wave == "square"*/ argv[2] == "square"){
			 // square wave
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
            else if(/*wave == "sawtooth"*/ argv[2] == "sawtooth"){
			 // saw wave
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
            else if(/*wave == "sine"*/argv[2] == "sine"){
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
           else if(/*wave == "triangle*/argv[2] == "triangle"){
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

            //else if(/*wave == "pulse"*/argv[2] == "pulse"){
            //}
		}
	}
	audioErr = AudioFileClose(audioFile);
	assert (audioErr == noErr);
	NSLog (@"wrote %ld samples", sampleCount);
	
    return 0;
}
