//
//  SettingsView.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 1/27/23.
//

import SwiftUI


struct SettingsView: View {
    typealias MCCPeer = GameViewModel.MCCPeer
    
    @StateObject var model: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Main Player")) {
                TextInputItem(title:"Name", defaultText:"Main Player Name", text:$model.mainPlayer.name)
                ColorPicker(title:"Color", color:$model.mainPlayer.color)
                TextInputItem(title:"Icon", defaultText:"Main Player Icon", text:$model.mainPlayer.icon)
            }

            Section(header: Text("")) {
                Toggle("Multiplayer", isOn: $model.isMultiplayer)
            }

            if model.isMultiplayer {
                if !model.isConnected {
                    Section(header: Text("Guest local player")) {
                        TextInputItem(title:"Name", defaultText:"Guest Player Name", text:$model.guestPlayer.name)
                        ColorPicker(title:"Color", color:$model.guestPlayer.color)
                        TextInputItem(title:"Icon", defaultText:"Guest Player Icon", text:$model.guestPlayer.icon)
                    }
                }
                
                Section(header: Text("Remote Players")) {
                    if model.availablePeers.isEmpty && model.isMultiplayer {
                        PeerView(name:"Searching for remore players...", state:.connecting)
                    } else {
                        ForEach(model.availablePeers) { peer in
                            PeerView(name:peer.name, state:peer.state)
                                .onTapGesture {
                                    if !model.peerTouched(peer) {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }
                        }
                    }
                }
            } else {
                Section(header: Text("Local Players")) {
                    PeerView(name:"Easy", state:.connected)
                    PeerView(name:"Medium", state:.idle)
                    PeerView(name:"Hard", state:.idle)
                }
            }
        }
        .toolbar {
            toolBarItem()
        }
        .alert(isPresented: $model.isShowingAlert) {
            (model.alert ?? {Alert(title: Text("Alert is nil..."))})()
        }
    }
    
    struct TextInputItem: View {
        @FocusState private var isTextFieldFocused: Bool
        @State private var memText = ""
        let title: String
        let defaultText: String
        var text: Binding<String>
        
        var body: some View {
            HStack {
                Text(title)
                TextField(defaultText, text: text)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.gray)
                    .focused($isTextFieldFocused)
                    .onChange(of: isTextFieldFocused) { isFocused in
                        if isFocused {
                            memText = text.wrappedValue
                            text.wrappedValue = ""
                        } else {
                            if text.wrappedValue == "" {
                                text.wrappedValue = memText
                            }
                        }
                    }
            }
        }
    }
    
    struct ColorPicker: View {
        private let colors = ["Red", "Yellow", "Green", "Blue", "Pink", "Purple", "Orange"]
        let title: String
        var color: Binding<String>
        
        var body: some View {
            Picker(title, selection: color) {
                ForEach(colors, id: \.self) { item in
                    Text(item).tag("Color" + item)
                }
            }
        }
    }
    
    struct PeerView: View {
        var name: String
        var state: MCCPeer.MCCPeerState
        
        var body: some View {
            HStack {
                Text(name)
                Spacer()
                if state == .connecting {
                    ProgressView()
                } else if state == .connected {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    func toolBarItem() -> ToolbarItem<(), Button<Text>> {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                dismiss()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: GameViewModel())
    }
}



