//
//  TicTacToeApp.swift
//  TicTacToe
//
//  Created by Aloysio Nandi Tiscoski on 1/23/23.
//

import SwiftUI

@main
struct TicTacToeApp: App {
    var body: some Scene {
        let game = GameViewModel()
        
        WindowGroup {
            NavigationView {
                GameView(model:game)
            }
        }
    }
}
