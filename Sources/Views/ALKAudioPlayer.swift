//
//  ALKAudioPlayer.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import AVFoundation
import UIKit

protocol ALKAudioPlayerProtocol: AnyObject {
    func audioPlaying(maxDuratation: CGFloat, atSec: CGFloat, lastPlayTrack: String)
    func audioStop(maxDuratation: CGFloat, lastPlayTrack: String)
    func audioPause(maxDuration: CGFloat, atSec: CGFloat, identifier: String)
}

final class ALKAudioPlayer {
    // sound file
    private var audioData: NSData?
    private var audioPlayer: AVAudioPlayer!
    private var audioLastPlay: String = ""

    private var timer = Timer()
    var secLeft: CGFloat = 0.0
    var maxDuration: CGFloat = 0.0
    weak var audiDelegate: ALKAudioPlayerProtocol?

    func playAudio() {
        if audioData != nil, maxDuration > 0 {
            if secLeft == 0 {
                secLeft = CGFloat(audioPlayer.duration)
            }

            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ALKAudioPlayer.updateCounter), userInfo: nil, repeats: true)

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            } catch {
                print("Error while setting AVAudioSession category: ", error.localizedDescription)
            }

            audioPlayer.stop()
            audioPlayer.play()
        }
    }

    func playAudioFrom(atTime: CGFloat) {
        if audioData != nil, maxDuration > 0 {
            if secLeft <= 0 {
                secLeft = CGFloat(audioPlayer.duration)
            }
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ALKAudioPlayer.updateCounter), userInfo: nil, repeats: true)

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            } catch {
                print("Error while setting AVAudioSession category: ", error.localizedDescription)
            }

            audioPlayer.currentTime = TimeInterval(atTime)
            audioPlayer.play()
        } else {
            stopAudio()
        }
    }

    func pauseAudio() {
        if audioData != nil, secLeft > 0 {
            timer.invalidate()
            audioPlayer.pause()
            audiDelegate?.audioPause(maxDuration: maxDuration, atSec: secLeft, identifier: audioLastPlay)
        } else {
            timer.invalidate()
            audioPlayer.stop()

            if audiDelegate != nil {
                audiDelegate?.audioStop(maxDuratation: maxDuration, lastPlayTrack: audioLastPlay)
            }
        }
    }

    func stopAudio() {
        if audioData != nil {
            if secLeft > 0 {
                pauseAudio()
            } else {
                secLeft = 0
                timer.invalidate()
                audioPlayer.stop()
                if audiDelegate != nil {
                    audiDelegate?.audioStop(maxDuratation: maxDuration, lastPlayTrack: audioLastPlay)
                }
            }
        }
    }

    func getCurrentAudioTrack() -> String {
        return audioLastPlay
    }

    @objc private func updateCounter() {
        if secLeft <= 0 {
            secLeft = 0
            timer.invalidate()
            audioPlayer.stop()

            if audiDelegate != nil {
                audiDelegate?.audioStop(maxDuratation: maxDuration, lastPlayTrack: audioLastPlay)
            }
        } else {
            secLeft -= 1
            if audiDelegate != nil {
                let timeLeft = audioPlayer.duration - audioPlayer.currentTime
                audiDelegate?.audioPlaying(maxDuratation: maxDuration, atSec: CGFloat(timeLeft), lastPlayTrack: audioLastPlay)
            }
        }
    }

    func setAudioFile(data: NSData, delegate: ALKAudioPlayerProtocol, playFrom: CGFloat, lastPlayTrack: String) {
        // setup player
        do {
            audioData = data
            audioPlayer = try AVAudioPlayer(data: data as Data, fileTypeHint: AVFileType.wav.rawValue)
            audioPlayer?.prepareToPlay()
            audioPlayer.volume = 1.0
            audiDelegate = delegate
            audioLastPlay = lastPlayTrack

            secLeft = playFrom
            maxDuration = CGFloat(audioPlayer.duration)

            if maxDuration == playFrom || playFrom <= 0 {
                playAudio()
            } else {
                let startFrom = maxDuration - playFrom
                if playFrom <= 0 {
                    playAudio()
                } else {
                    playAudioFrom(atTime: startFrom)
                }
            }

        } catch _ as NSError {}
    }
}
