//
//  ViewController.swift
//  CocoaApp#1
//
//  Created by Sean Smith on 7/8/19.
//  Copyright © 2019 Sean Smith. All rights reserved.
//

import Cocoa
import AudioToolbox
import AVFoundation

class ViewController: NSViewController {
    private let operationQueue: OperationQueue = OperationQueue()
    
    @IBOutlet var levelMeter: NSLevelIndicator!
    @IBOutlet var horizontalSlider: NSSlider!
    @IBOutlet var dispNum: NSTextFieldCell!
    @IBOutlet weak var distanceSlider: NSSlider!
    @IBOutlet weak var distanceMeter: NSLevelIndicator!
    @IBOutlet weak var rotateSource: NSSliderCell!
    @IBOutlet weak var rotationMeter: NSLevelIndicatorCell!
    
    var curPlayer: playerStruct? = nil
    var isPlaying: Bool = false
    var radius: Float = 1.0
    var runCount: UInt32 = 0
    let fileNameWithPath = "/Users/Sean/Desktop/Media/Input.wav"
    //let fileNameWithPath = "/Users/ssmith/Desktop/Media/InputMono.wav"

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        horizontalSlider.isContinuous = true
        horizontalSlider.doubleValue = 0.5
        horizontalSlider.minValue = 0
        horizontalSlider.maxValue = 1.0
        levelMeter.isContinuous = true
        levelMeter.minValue = 0
        levelMeter.maxValue = 100
        levelMeter.doubleValue = 50

        
        //3D Settings
        distanceSlider.isContinuous = true
        distanceSlider.minValue = 0.5
        distanceSlider.maxValue = 5
        distanceSlider.doubleValue = 1
        distanceMeter.minValue = 0.5
        distanceMeter.maxValue = 5
        distanceMeter.doubleValue = 1
        
        //rotation settings
        //rotationMeter.isContinuous = true
        rotationMeter.minValue = 0
        rotationMeter.maxValue = 2 * Double.pi
        rotateSource.isContinuous = true
        rotateSource.minValue = 0
        rotateSource.maxValue = 2 * Double.pi
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func whenSliding(_ sender: Any) {
        levelMeter.doubleValue = horizontalSlider.doubleValue * 100
        dispNum.title = String(format: "%.2f", horizontalSlider.doubleValue * 100)
        self.setMixerVolume(player: self.curPlayer!, volume: self.horizontalSlider.floatValue)
    }
    
    @IBAction func whenPushed(_ sender: Any) {
        horizontalSlider.doubleValue = 0.0
        levelMeter.doubleValue =    horizontalSlider.doubleValue
        dispNum.title = String(format: "%.2f", horizontalSlider.doubleValue)
        self.setMixerVolume(player: self.curPlayer!, volume: self.horizontalSlider.floatValue)
    }

    @IBAction func pushPlay(_ sender: Any) {
        if(isPlaying == false){
            curPlayer = setUpPlayback (fn: fileNameWithPath)
            isPlaying = true
        }
        operationQueue.addOperation{
            self.playFile(player: self.curPlayer!)
        }
    }
    
    @IBAction func pushPause(_ sender: Any) {
        operationQueue.addOperation{
            self.pausePlayback(player: self.curPlayer!)
        }
    }
    
    @IBAction func pushStop(_ sender: Any) {
        operationQueue.addOperation{
            self.stopPlayback(player: self.curPlayer!)
        }
        isPlaying = false
    }
    
    @IBAction func distanceSliding(_ sender: Any) {
        distanceMeter.doubleValue = distanceSlider.doubleValue
        if((curPlayer) != nil){
            radius = distanceSlider.floatValue
            calcRotation(player: self.curPlayer!, phase: self.rotateSource.floatValue)
        }
    }
    
    @IBAction func whenRotating(_ sender: Any) {
        rotationMeter.doubleValue = rotateSource.doubleValue
        if((curPlayer) != nil){
            calcRotation(player: self.curPlayer!, phase: self.rotateSource.floatValue)
        }
    }
    @IBAction func autoRotate(_ sender: Any) {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if((self.curPlayer) != nil){
                self.calcRotation(player: self.curPlayer!, phase: self.rotateSource.floatValue)
            }
            self.rotateSource.floatValue += (2 * Float.pi)/1000
            self.runCount += 1
            
            if self.runCount == 1000 {
                timer.invalidate()
                self.runCount = 0
                self.rotateSource.floatValue -= (2 * Float.pi)
            }
        }
    }
    
}
extension ViewController{
    
    struct playerStruct{
        var engine: AVAudioEngine = AVAudioEngine()
        var playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
        var mixerNode: AVAudioEnvironmentNode = AVAudioEnvironmentNode()
        var delayNode = AVAudioUnitDelay()
        var reverbNode = AVAudioUnitReverb()
        var duration: UInt32 = 0
        
        init(engine: AVAudioEngine, playerNode: AVAudioPlayerNode, mixerNode: AVAudioEnvironmentNode, duration: UInt32,
             reverbNode: AVAudioUnitReverb, delayNode: AVAudioUnitDelay){
            self.engine = engine
            self.playerNode = playerNode
            self.reverbNode = reverbNode
            self.duration = duration
        }
    }
    
    func setUpPlayback(fn: String) -> playerStruct{
        let playDuration: UInt32 = getFileDuration(fn);
        print("The file duration in seconds is \(playDuration)")
        let playerInstance = playerStruct(engine: AVAudioEngine(), playerNode: AVAudioPlayerNode(), mixerNode: AVAudioEnvironmentNode(), duration: playDuration,  reverbNode: AVAudioUnitReverb(), delayNode: AVAudioUnitDelay())
        
        //Attach the nodes
        playerInstance.engine.attach(playerInstance.playerNode)
        playerInstance.engine.attach(playerInstance.mixerNode)
        
        //Connect the nodes
        playerInstance.engine.connect(playerInstance.playerNode, to: playerInstance.mixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: 44100, channels: 1))
        playerInstance.engine.connect(playerInstance.mixerNode, to: playerInstance.engine.mainMixerNode, format: nil)
        
        //Set mixer volume to default
        playerInstance.mixerNode.outputVolume = horizontalSlider.floatValue
        
        //Set up environmental factors
        
        playerInstance.mixerNode.listenerPosition = AVAudio3DPoint(x:0.0, y:0.0, z:0.0)
        playerInstance.mixerNode.position = AVAudio3DPoint(x:0.0, y:0.0, z:0.0)
        playerInstance.mixerNode.obstruction = 0.0
        playerInstance.mixerNode.occlusion = 0.0
        playerInstance.mixerNode.reverbBlend = 0.5
        
        //Prepare the engine
        playerInstance.engine.prepare()
        
        
        //schedule the file
        do{
            //local files
            let url = URL(fileURLWithPath: fileNameWithPath)
            let file = try AVAudioFile(forReading: url)
            playerInstance.playerNode.scheduleFile(file, at: nil, completionHandler: nil)
            print("Audio file scheduled")
            
        }catch{
            print("Failed to create file: \(error.localizedDescription)")
        }
        
        return playerInstance
        
        
    }
    func playFile(player: playerStruct){
        do{
            try player.engine.start()
            print("Engine started")
            player.playerNode.play()
            print("File played")
        }catch{
            print("Failed to start engine: \(error.localizedDescription)")
        }
    }
    func stopPlayback(player: playerStruct){
        player.playerNode.stop()
    }
    func pausePlayback(player: playerStruct){
        player.playerNode.pause()
    }
    func setMixerVolume(player: playerStruct, volume: Float){
        player.mixerNode.outputVolume = volume
    }
    func calcRotation(player: playerStruct, phase: Float){
        let xVal = radius * sin(phase)
        let zVal = radius * cos(phase)
        player.playerNode.position = AVAudio3DPoint(x:xVal, y:0, z:zVal)
    }

}
