//
//  SoundPlayer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import AVFoundation

struct SoundPlayer {
    static func playSound(forKey key: String, andExtension ext: String) {
        if let soundURL = Bundle.main.url(forResource: key, withExtension: ext) {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound)
        }
    }
}
