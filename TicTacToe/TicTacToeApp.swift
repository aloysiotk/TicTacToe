//
//  TicTacToeApp.swift
//  TicTacToe
//
//  Created by Aloysio Nandi Tiscoski on 1/23/23.
//

import SwiftUI

@main
struct TicTacToeApp: App {
    @StateObject var alertHandler = AlertHandler()
    
    var body: some Scene {
        let game = ViewModel(alertHandler: alertHandler)
        
        WindowGroup {
            NavigationStack {
                GameView(model:game)
            }
            .environmentObject(alertHandler)
        }
    }
}
