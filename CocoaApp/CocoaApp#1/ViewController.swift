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
    
    @IBOutlet weak var levelMeter: NSLevelIndicator!
    @IBOutlet weak var horizontalSlider: NSSlider!
    @IBOutlet weak var dispNum: NSTextFieldCell!
    @IBOutlet weak var reverbSlider: NSSliderCell!
    @IBOutlet weak var delaySlider: NSSliderCell!
    
    @IBOutlet weak var reverbButton: NSButton!
    @IBOutlet weak var delayButton: NSButton!
    
    var curPlayer: playerStruct? = nil
    var isPlaying: Bool = false
    let fileNameWithPath = "/Users/Sean/Desktop/Media/Input.wav"
    //let fileNameWithPath = "/Users/ssmith/Desktop/Media/Input.wav"
    
    var reverbStatus: Bool = false
    var delayStatus: Bool = false
    
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
        
        //Effects settings
        reverbSlider.isContinuous = true
        reverbSlider.doubleValue = 50
        reverbSlider.minValue = 0
        reverbSlider.maxValue = 100
        delaySlider.isContinuous = true
        delaySlider.doubleValue = 50
        delaySlider.minValue = 0
        delaySlider.maxValue = 100
        
        //start delay and reverb as off
        reverbButton.state = .off
        delayButton.state = .off
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
    
    @IBAction func reverbPushed(_ sender: Any) {
        if(reverbStatus == true){
            reverbStatus = false
            self.curPlayer?.reverbNode.wetDryMix = 0.0
        }
        else{
            reverbStatus = true
            self.curPlayer?.reverbNode.wetDryMix = reverbSlider.floatValue
        }
    }
    
    @IBAction func delayPushed(_ sender: Any) {
        if(delayStatus == true){
            delayStatus = false
            self.curPlayer?.delayNode.wetDryMix = 0.0
        }
        else{
            delayStatus = true
            self.curPlayer?.delayNode.wetDryMix = delaySlider.floatValue
        }
    }
    
    @IBAction func reverbSliding(_ sender: Any) {
        if(reverbStatus == true){
            self.curPlayer?.reverbNode.wetDryMix = reverbSlider.floatValue
        }
        else{
            self.curPlayer?.reverbNode.wetDryMix = 0.0
        }
    }
    
    @IBAction func delaySliding(_ sender: Any) {
        if(delayStatus == true){
            self.curPlayer?.delayNode.wetDryMix = delaySlider.floatValue
        }
        else{
            self.curPlayer?.delayNode.wetDryMix = 0.0

        }
    }
    
}
extension ViewController{
    
    struct playerStruct{
        var engine: AVAudioEngine = AVAudioEngine()
        var playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
        var mixerNode: AVAudioMixerNode = AVAudioMixerNode()
        var delayNode = AVAudioUnitDelay()
        var reverbNode = AVAudioUnitReverb()
        var duration: UInt32 = 0
        
        init(engine: AVAudioEngine, playerNode: AVAudioPlayerNode, mixerNode: AVAudioMixerNode, duration: UInt32,
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
        let playerInstance = playerStruct(engine: AVAudioEngine(), playerNode: AVAudioPlayerNode(), mixerNode: AVAudioMixerNode(), duration: playDuration,  reverbNode: AVAudioUnitReverb(), delayNode: AVAudioUnitDelay())
        
        //Attach the nodes
        playerInstance.engine.attach(playerInstance.playerNode)
        playerInstance.engine.attach(playerInstance.mixerNode)
        playerInstance.engine.attach(playerInstance.delayNode)
        playerInstance.engine.attach(playerInstance.reverbNode)
        
        //Connect the nodes
        playerInstance.engine.connect(playerInstance.playerNode, to: playerInstance.delayNode, format: nil)
        playerInstance.engine.connect(playerInstance.delayNode, to: playerInstance.reverbNode, format: nil)
        playerInstance.engine.connect(playerInstance.reverbNode, to: playerInstance.mixerNode, format: nil)
        playerInstance.engine.connect(playerInstance.mixerNode, to: playerInstance.engine.mainMixerNode, format: nil)
        
        //Set mixer volume to default
        playerInstance.mixerNode.outputVolume = horizontalSlider.floatValue
        
        //Set delay and reverb parameters
        playerInstance.delayNode.delayTime = 1.6
        playerInstance.delayNode.feedback = 0
        playerInstance.delayNode.wetDryMix = 0
        playerInstance.reverbNode.wetDryMix = 0
        playerInstance.reverbNode.loadFactoryPreset(AVAudioUnitReverbPreset.mediumChamber)
        
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
}
