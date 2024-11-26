//
//  MeterViewController.swift
//  OMMeter
//
//  Created by Jorge Ouahbi on 7/11/16.
//  Copyright © 2022 Jorge Ouahbi. All rights reserved.
//

import UIKit
import AVFoundation
protocol SoundPlayer {
    func playSound(name: String, withExtension: String, numberOfLoops: Int, meteringEnabled: Bool)
    func updatePlayerMeters()
}
@available(iOS 13.0, *)
class MeterViewController: UIViewController {
    @IBOutlet weak var audioMeterSteroR: OMMeter!
    @IBOutlet weak var audioMeterSteroL: OMMeter!
    var isAveragePower: Bool = true
    var isPlayer: Bool = false
    var player: AVAudioPlayer = AVAudioPlayer()
    var micMonitor: MicrophoneMonitor?
    @objc func updateMeters() {
        if !isPlayer {
            if let mic = micMonitor {
                if self.isAveragePower {
                    let averagePower = mic.averagePower.first!
                    audioMeterSteroR.value = CGFloat(averagePower)
                    audioMeterSteroL.value = CGFloat(averagePower)
                } else {
                    let peakPower = mic.peakPower.first!
                    audioMeterSteroR.value = CGFloat(peakPower)
                    audioMeterSteroL.value = CGFloat(peakPower)
                }
            }
        } else {
            updatePlayerMeters()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // R meter
        audioMeterSteroR.minimumValue = -80
        audioMeterSteroR.maximumValue = 20
        audioMeterSteroR.gradientColors = [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red]
        // L meter
        audioMeterSteroL.minimumValue = -80
        audioMeterSteroL.maximumValue = 20
        audioMeterSteroL.gradientColors = [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red]
        if isPlayer {
            playSound(name: "atmosbasement", withExtension: "mp3")
        } else {
            // The microphone its mono
            self.micMonitor = MicrophoneMonitor(numberOfSamples: 1)
        }
        let dpLink = CADisplayLink( target: self, selector: #selector(updateMeters))
        dpLink.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
}

@available(iOS 13.0, *)
extension MeterViewController: SoundPlayer {
    func updatePlayerMeters() {
        if player.isPlaying {
            player.updateMeters()
            var power = 0.0
            var peak  = 0.0
            for index in 0 ..< player.numberOfChannels {
                power = Double(player.averagePower(forChannel: index))
                peak  = Double(player.peakPower(forChannel: index))
                if self.isAveragePower {
                    if index == 0 {
                        audioMeterSteroR.value = CGFloat(power)
                    } else {
                        audioMeterSteroL.value = CGFloat(power)
                    }
                } else {
                    if index == 0 {
                        audioMeterSteroR.value = CGFloat(peak)
                    } else {
                        audioMeterSteroL.value = CGFloat(peak)
                    }
                }
            }
        }
    }
    func playSound(name: String, withExtension: String = "mp3", numberOfLoops: Int = -1, meteringEnabled: Bool = true) {
        guard let url = Bundle.main.url(forResource: name, withExtension: withExtension) else {
            print("Unable to locate the audio file \(name)")
            return
        }
        do {
            /// this codes for making this app ready to takeover the device audio
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            /// change fileTypeHint according to the type of your audio file (you can omit this)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            player.isMeteringEnabled = meteringEnabled
            player.numberOfLoops     = numberOfLoops
            // no need for prepareToPlay because prepareToPlay is happen automatically when calling play()
            player.play()
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
}
