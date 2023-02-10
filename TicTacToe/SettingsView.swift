//
//  SettingsView.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 1/27/23.
//

import SwiftUI


struct SettingsView: View {
    @StateObject var model: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Player 1")) {
                TextInputItem(title: "Name", defaultText: "Player 1 Name", text: $model.mainPlayer.name)
                ColorPicker(title: "Color", color: $model.mainPlayer.color)
                TextInputItem(title: "Icon", defaultText: "Player 1 Icon", text: $model.mainPlayer.icon)
            }
            if !model.isMultipeerOn {
                Section(header: Text("Player 2")) {
                    TextInputItem(title: "Name", defaultText: "Player 2 Name", text: model.guestPlayer!.bindingName())
                    ColorPicker(title: "Color", color: model.guestPlayer!.bindingColor())
                    TextInputItem(title: "Icon", defaultText: "Player 2 Icon", text: model.guestPlayer!.bindingIcon())
                }
            }
            
            Section(header: Text("Available Players")) {
                Toggle("Multipeer", isOn: $model.isMultipeerOn)
                if model.availablePeers.isEmpty && model.isMultipeerOn {
                    Text("Searching nearby players...")
                } else {
                    ForEach(model.availablePeers) { peer in
                        PeerView(peer: peer)
                            .onTapGesture {
                                if peer.state == .idle && !model.isConnecting {
                                    model.invitePeer(peer)
                                }
                            }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .alert(isPresented: $model.isShowingInvitation) {
            invitationAlert()
        }
        .onAppear{model.startAdvertising()}
        .onDisappear{model.stopAdvertising()}
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
        var peer: MCConnector.MCCPeer
        
        var body: some View {
            HStack {
                Text(peer.name)
                Spacer()
                if peer.state == .connecting {
                    ProgressView()
                } else if peer.state == .connected {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    func invitationAlert() -> Alert {
        let peer = model.firstPendingInvitation
        
        return Alert(
            title: Text("Invitation received."),
            message: Text("\(peer!.name) would like to play with you."),
            primaryButton: .default(Text("Decline")) {
                model.respondInvitation(false, forPeer: peer!)
            },
            secondaryButton: .default(Text("Accept")) {
                model.respondInvitation(true, forPeer: peer!)
            }
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: GameViewModel())
    }
}



