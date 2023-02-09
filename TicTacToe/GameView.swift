//
// GametView.swift
// TicTacToe
//
// Created by Aloysio Nandi Tiscoski on 1/23/23.
//

import SwiftUI

struct GameView: View {
    
    @StateObject var model: GameViewModel
    @State private var isShowingSettings = false
    var vGridLayout = [GridItem(), GridItem(), GridItem()]
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        GameBoardGrid(columns: model.columns, itens: model.cards){ item in
                            CardView(content: item.owner?.icon ?? "", color: Color(item.owner?.color ?? "ColorRed") )
                                .onTapGesture {
                                    withAnimation(.linear) {
                                        if !model.choose(boardItem: item) {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }
                                }
                        }
                        if model.gameFinished {
                            Color("MainBackground")
                                .cornerRadius(20)
                                .opacity(0.7)
                            if model.hasWinner {
                                Text("\(model.playerInTurn.name) Won the game!")
                                    .foregroundColor(Color(model.playerInTurn.color))
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
                Text("\(model.playerInTurn.name)'s turn")
                    .foregroundColor(Color(model.playerInTurn.color))
                    .padding(.top)
                Spacer()
                    Image(systemName:"arrow.clockwise")
                        .padding(.horizontal)
                        .onTapGesture {
                            withAnimation(.linear) {
                                model.startANewGame()
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
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
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
    
    struct CardView: View {
        var content: String
        var color: Color
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color("MainBackground")
                        .opacity(0.1)
                    Text(content)
                        .font(Font.custom("Chalkduster", size: geometry.size.height * 0.7))
                        .foregroundColor(color)
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
