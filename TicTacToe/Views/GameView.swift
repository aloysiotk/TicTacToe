//
// GametView.swift
// TicTacToe
//
// Created by Aloysio Nandi Tiscoski on 1/23/23.
//

import SwiftUI

struct GameView: View {
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var model: ViewModel

    private let gameFinishedDelay = 0.5
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                GameBoardGrid(columns: model.columns, items: model.boardItems){ item in
                    BoardItemView(owner: item.owner, action: {model.choose(position: item.position)})
                }
                gameFinishedView()
            }
            .padding()
            Spacer()
            Text("\(model.playerInTurnName)'s turn")
                .foregroundColor(Color(model.playerInTurnColor.rawValue))
                .padding()
                .background(.clear)
                .animation(.snappy, value: model.playerInTurnName)
            Spacer()
            restartButton()
        }
        .background(Color(.mainBackground))
        .font(Font.custom("Chalkduster", size: 30))
        .toolbar {settingsButton()}
        .onChange(of: scenePhase) { sp in scenePhaseDidChange(newPhase: sp)}
        .onChange(of: model.hasWinner) { _ in playSoundIfHasWinner()}
        .sheet(isPresented: $model.isShowingSettings) {SettingsView(model:model)}
        .alertable()
    }
    
    private func playSoundIfHasWinner() {
        if model.hasWinner {
            DispatchQueue.main.asyncAfter(deadline: .now() + gameFinishedDelay) {
                SoundPlayer.playSound(forKey: "Applause", andExtension: "mp3")
            }
        }
    }
    
    private func settingsButton() -> some View {
        Button (action: {model.isShowingSettings = true}) {
            Image(systemName: "gearshape")
        }
    }
    
    private func restartButton() -> some View {
        Button(action: {
            withAnimation(.linear) {
                model.restart()
            }
        }, label: {
            Image(systemName: "arrow.clockwise")
        })
    }
    
    private func gameFinishedView() -> some View {
        Group {
            Color(.mainBackground)
                .opacity(model.isGameFinished ? 0.7 : 0)
            Text(model.gameFinishedText)
                .foregroundColor(model.gameFinishedColor)
                .font(Font.custom("Chalkduster", size: 60))
                .multilineTextAlignment(.center)
        }
        .animation(.easeInOut.delay(model.isGameFinished ? gameFinishedDelay : 0), value: model.isGameFinished)
    }
    
    private func scenePhaseDidChange(newPhase: ScenePhase) {
        if newPhase == .background {
            model.didEnterInBackground()
        }
    }
    
    struct BoardItemView: View {
        var owner: Player?
        var action: () -> Bool
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color(.mainBackground)
                        .opacity(0.01)
                    Text(owner?.icon ?? "")
                        .font(Font.custom("Chalkduster", size: geometry.size.height * 0.7))
                        .foregroundColor(Color(owner?.color.rawValue ?? "red"))
                        .animation(.easeInOut, value: owner?.icon)
                }
                .onTapGesture {boardItemWasTapped()}
            }
        }
        
        private func boardItemWasTapped() {
            if !action() {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let alertHandler = AlertHandler()
        GameView(model:ViewModel(alertHandler: alertHandler))
            .environmentObject(alertHandler)
    }
}
