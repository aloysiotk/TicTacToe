//
//  SettingsView.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 1/27/23.
//

import SwiftUI


struct SettingsView: View {
    @ObservedObject var model: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                playerSection(title: "Main Player", player: $model.mainPlayer)
                Section {Toggle("Multiplayer", isOn: $model.isMultiplayer)}
                
                if model.isMultiplayer {
                    if !model.isConnected {
                        playerSection(title: "Guest Local Player", player: $model.guestPlayer)
                    }
                    remotePlayersSection()
                } else {
                    automatedPlayersSection()
                }
            }
            .toolbar {
                closeButton()
            }
        }
        .alertable()
    }
    
    private func remotePlayersSection() -> some View {
        Section(header: Text("Remote Players")) {
            if model.availablePeers.isEmpty && model.isMultiplayer {
                PeerView(name:"Searching for remote players...", state:.connecting, action: {})
            } else {
                ForEach(model.availablePeers) { peer in
                    PeerView(name:peer.name, state:peer.state, action: {remotePeerTouched(peer)})
                }
            }
        }
    }
    
    private func playerSection(title: String, player: Binding<Player>) -> some View {
        Section(header: Text(title)) {
            TextInputItem(title:"Name", defaultText:"Player Name", text:player.name)
            EnumPicker(label: "Color", selection: player.color)
            TextInputItem(title:"Icon", defaultText:"Player Icon", text:player.icon)
        }
    }
    
    private func automatedPlayersSection() -> some View {
        Section(header: Text("Automated Players")) {
            ForEach(model.availablePeers) { peer in
                PeerView(name:peer.name, state:peer.state, action: {model.selectAutomatedPlayer(peer.id)})
            }
        }
    }
    
    private func closeButton() -> ToolbarItem<(), Button<Text>> {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                dismiss()
            }
        }
    }
    
    private func remotePeerTouched(_ peer: TTTPeer) {
        if !model.peerTouched(peer) {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    struct PeerView: View {
        var name: String
        var state: TTTPeer.MCCPeerState
        var action: () -> Void
        
        var body: some View {
            HStack {
                Button(name) {action()}
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
                if state == .connecting {
                    ProgressView()
                } else if state == .connected {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let alertHandler = AlertHandler()
        SettingsView(model: ViewModel(alertHandler: alertHandler))
            .environmentObject(alertHandler)
    }
}



