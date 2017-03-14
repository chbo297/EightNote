//
//  VoiceDetector.swift
//  EightNote
//
//  Created by bo on 14/03/2017.
//  Copyright © 2017 bo. All rights reserved.
//

import UIKit
import AVFoundation

protocol VoiceDetectorDelegate : NSObjectProtocol {
    func lowVoice()
    
    func highVoice(_ voice : CGFloat)
    
    func silence()
}

class VoiceDetector : NSObject {

    var link : CADisplayLink?
    
    weak var delegate : VoiceDetectorDelegate?
    
    lazy var recoder : AVAudioRecorder = {
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        
        let settingdic : [String : Any] = [
                AVFormatIDKey: NSNumber(value: kAudioFormatAppleIMA4),
                AVNumberOfChannelsKey: 1, 
                AVEncoderAudioQualityKey : AVAudioQuality.medium.rawValue,
                AVEncoderBitDepthHintKey : 16,
                AVSampleRateKey : 44100.0
        ]
        
        let dir = NSTemporaryDirectory()
        let path = dir + "/rec.caf"

        let rec = try! AVAudioRecorder.init(url: URL.init(string: path)!, settings: settingdic)
        rec.isMeteringEnabled = true
        rec.prepareToRecord()

        return rec
        
    }()
    
    func linkClock() {
        self.recoder.updateMeters()
//        print("average:\(self.recoder.averagePower(forChannel: 0))")
//        print("peek:\(self.recoder.peakPower(forChannel: 0))")
        let peek = -self.recoder.peakPower(forChannel: 0)
        
        if (self.delegate == nil) {
            return
        }
        
        if (peek > 11) {
            self.delegate?.silence()
        } else if (peek > 3.2) {
            self.delegate?.lowVoice()
        } else {
            self.delegate?.highVoice(CGFloat(3.2 - peek) / CGFloat(40))
        }
    }
    
    func startDetect() {
        self.recoder.record()
        self.link = CADisplayLink.init(target: self, selector: #selector(self.linkClock))
        self.link?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func stopDetect() {
        self.recoder.stop()
    }
    
}
