//
// GametView.swift
// TicTacToe
//
// Created by Aloysio Nandi Tiscoski on 1/23/23.
//

import SwiftUI

struct GameView: View {
    typealias BoardItem = TicTacToeGame.Board.BoardItem
    
    @StateObject var model: GameViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        GameBoardGrid(columns: model.columns, itens: model.boardItens){ item in
                            BoardItemView(icon: item.owner?.icon ?? "", color: item.owner?.color ?? "ColorRed")
                                .onTapGesture {
                                    withAnimation(.linear) {
                                        if !model.choose(position: item.position) {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }
                                }
                        }
                        if model.isGameFinished {
                            Color("MainBackground")
                                .cornerRadius(20)
                                .opacity(0.7)
                            if model.hasWinner {
                                Text("\(model.playerInTurnName) Won the game!")
                                    .foregroundColor(Color(model.playerInTurnColor))
                                    .onAppear() {
                                        SoundPlayer.playSound(forKey: "Applause", andExtension: "mp3")
                                    }
                            } else {
                                Text("Tied game...")
                                    .foregroundColor(.gray)
                            }
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
                    .padding(.top)
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
            Alert(
                title: Text("No Player connected."),
                message: Text("Connect to a remote player to start the game.")
            )
        }
    }
    
    struct BoardItemView: View {
        var icon: String
        var color: String
        
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
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(model:GameViewModel())
    }
}
