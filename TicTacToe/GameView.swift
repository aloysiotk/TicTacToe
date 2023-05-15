//
// GametView.swift
// TicTacToe
//
// Created by Aloysio Nandi Tiscoski on 1/23/23.
//

import SwiftUI

struct GameView: View {
    typealias BoardItem = GameViewModel.Board.BoardItem
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var model: GameViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        GameBoardGrid(columns: model.columns, itens: model.boardItens){ item in
                            BoardItemView(icon: item.owner?.icon, color: item.owner?.color, position:item.position, model: model)
                        }
                        if model.isGameFinished {
                            GameFinshedView(model: model)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .font(Font.custom("Chalkduster", size: 60))
                    .multilineTextAlignment(.center)
                    Spacer()
                }
                Spacer()
                Text("\(model.playerInTurnName)'s turn")
                    .foregroundColor(Color(model.playerInTurnColor))
                Spacer()
                Image(systemName:"arrow.clockwise")
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation(.linear) {
                            model.restart()
                        }
                    }
                    .foregroundColor(.blue)
            }
            .background(Color("MainBackground"))
            .font(Font.custom("Chalkduster", size: 30))
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                model.didEnterInBackground()
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    model.isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $model.isShowingSettings) {
            NavigationView {
                SettingsView(model:model)
            }
        }
        .alert(isPresented: $model.isShowingAlert) {
            (model.alert ?? {Alert(title: Text("Alert is nil..."))})()
        }
    }
    
    struct GameFinshedView: View {
        var model: GameViewModel
        
        var body: some View {
            Color("MainBackground")
                .opacity(0.7)
            if model.hasWinner {
                Text("\(model.playerInTurnName) Won the game!")
                    .foregroundColor(Color(model.playerInTurnColor))
                    .onAppear() {
                        SoundPlayer.playSound(forKey: "Applause", andExtension: "mp3")
                    }
            } else {
                Text("Game is draw...")
                    .foregroundColor(.gray)
            }
        }
    }
    
    struct BoardItemView: View {
        var icon: String
        var color: String
        var position: GameViewModel.BoardPosition
        var model: GameViewModel
        
        
        init(icon: String?, color: String?, position: GameViewModel.BoardPosition, model: GameViewModel) {
            self.icon = icon ?? ""
            self.color = color ?? "ColorRed"
            self.position = position
            self.model = model
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color("MainBackground")
                        .opacity(0.01)
                    Text(icon)
                        .font(Font.custom("Chalkduster", size: geometry.size.height * 0.7))
                        .foregroundColor(Color(color))
                        .frame(alignment: .center)
                }
                .onTapGesture {
                    withAnimation(.linear) {
                        if !model.choose(position: position) {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(model:GameViewModel())
    }
}
