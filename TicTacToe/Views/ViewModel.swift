//
//  ViewModel.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import Foundation
import UIKit
import SwiftUI

class ViewModel: ObservableObject, MCConnectorDelegate {
    private var connection: TTTConnector?
    private var startRemoteGame: ((Player) -> TicTacToeGame)?
    
    private let automatedPlayers = [MiniMaxPlayer(id: 10, name: "Easy", icon: "O", color: .yellow, depth: 4),
                            MiniMaxPlayer(id: 11, name: "Medium", icon: "O", color: .orange, depth: 6),
                            MiniMaxPlayer(id: 12, name: "Hard", icon: "O", color: .red, depth: 10)]
    
    @Published private(set) var game: TicTacToeGame
    @Published var mainPlayer: Player
    @Published var guestPlayer: Player
    @Published var availablePeers: [TTTPeer] = []
    @Published var isMultiplayer = false {didSet{toggledMultiplayer()}}
    @Published var isShowingSettings = false
    
    var alertHandler: AlertHandler
    
    var boardItems: [BoardItem] {game.board.items}
    var columns: Int {game.board.columns}
    var playerInTurnName: String {game.playerInTurn.name}
    var playerInTurnColor: PlayerColors {game.playerInTurn.color}
    var isGameFinished: Bool {game.isGameFinished}
    var hasWinner: Bool {game.hasWinner}
    var isConnecting: Bool {!availablePeers.filter({$0.state == .connecting}).isEmpty}
    var isConnected: Bool {connection?.isConnected ?? false}
    
    var gameFinishedText: String {isGameFinished ? hasWinner ? "\(playerInTurnName) won the game!" : "Game is draw..." : ""}
    var gameFinishedColor: Color {hasWinner ? Color(playerInTurnColor.rawValue) : .gray}
    
    init(alertHandler: AlertHandler) {
        self.alertHandler = alertHandler

        let mainPlayer = LocalPlayer(id: 1)
        let guestPlayer = LocalPlayer(id: 2)
        
        self.mainPlayer = mainPlayer
        self.guestPlayer = guestPlayer
        self.game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
        self.isMultiplayer = DataHandler.retrieve(forKey: .isMultiPeerOn)
    }
    
    func selectAutomatedPlayer(_ peerId: Int) {
        guard let guestPlayer = automatedPlayers.element(by: peerId) else {fatalError("Unable to retrieve automated player.")}
        self.guestPlayer = guestPlayer
        
        DataHandler.store(data: peerId, forKey: .automatedPlayerSelectedId)
        
        availablePeers.forEach { availablePeer in
            availablePeers.updateState(availablePeer.id == peerId ? .connected : .idle, forPeer: availablePeer)
        }
        
        game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
    }
    
    func restart() {
        game.restart()
        
        if let connection = connection, connection.isConnected  {
            connection.send(.restart, withData: nil)
        } else if !isMultiplayer && game.playerInTurn == guestPlayer {
            automatedPlayerPlay(after: 0.5)
        }
    }
    
    private func automatedPlayerPlay(after: Double = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            self.guestPlayer.play(game: self.game, choose: self.automatedMove(position:))
        }
    }
    
    func choose(position: BoardPosition) -> Bool {
        if isConnected || !isMultiplayer {
            let isValidMove = game.choose(position: position, forPlayer:mainPlayer)
            
            if isValidMove {
                if isConnected {
                    connection!.send(.move, withData: position.encode())
                } else {
                    automatedPlayerPlay(after: 1)
                }
            }
            return isValidMove
        } else {
            return game.choose(position: position, forPlayer: game.playerInTurn)
        }
    }
    
    func didEnterInBackground() {
        stopAdvertising()
    }
    
    func peerTouched(_ peer: TTTPeer) -> Bool {
        if peer.state == .idle && (!isConnecting && !isConnected) {
            invitePeer(peer)
            return true
        } else if peer.state == .connected {
            connection?.disconnect()
            return true
        }
        return false
    }
    
    private func toggledMultiplayer() {
        DataHandler.store(data: isMultiplayer, forKey: .isMultiPeerOn)
        
        if isMultiplayer {
            guestPlayer = LocalPlayer(id: 2)
            game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
            connection = TTTConnector(withPublicName: mainPlayer.name, andDelegate: self)
            startAdvertising()
        } else {
            stopAdvertising()
            connection = nil
            populateAutomatedPlayers()
        }
    }
    
    private func populateAutomatedPlayers() {
        availablePeers = automatedPlayers.map({TTTPeer(id: $0.id, name: $0.name)})
        
        let selectedId: Int = DataHandler.retrieve(forKey: .automatedPlayerSelectedId) ?? 10
        selectAutomatedPlayer(selectedId)
    }
    
    private func automatedMove(position: BoardPosition) {
        game.choose(position: position, forPlayer: guestPlayer)
    }
    
    private func startAdvertising() {
        availablePeers = []
        connection?.startAdvertising()
    }
    
    private func stopAdvertising() {
        connection?.stopAdvertising()
        availablePeers = []
    }
    
    private func invitePeer(_ peer: TTTPeer) {
        availablePeers.updateState(.connecting, forPeer: peer)
        connection?.invitePeer(peer)
        startRemoteGame = newGameAsPlayer1(player2:)
    }
    
    private func respondInvitation(_ response: Bool, forPeer peer: TTTPeer) {
        if response == true {
            for awaitingPeer in availablePeers.awaitingResponse {
                availablePeers.updateState(peer == awaitingPeer ? .connecting : .idle, forPeer: awaitingPeer)
                connection?.respondInvitationFor(awaitingPeer, withValue: peer == awaitingPeer)
                startRemoteGame = newGameAsPlayer2(player1:)
            }
        } else {
            availablePeers.updateState(.idle, forPeer: peer)
            connection?.respondInvitationFor(peer, withValue: response)
            
            if let peer = availablePeers.awaitingResponse.first {
                alertHandler.showAlert(invitationReceivedAlert(from: peer), after: 0.3)
            }
        }
    }
    
    private func newGameAsPlayer1(player2: Player) -> TicTacToeGame {
        TicTacToeGame(player1: mainPlayer, player2: player2)
    }
    
    private func newGameAsPlayer2(player1: Player) -> TicTacToeGame {
        TicTacToeGame(player1: player1, player2: mainPlayer)
    }
    
    //MARK: - MCConnectorDelegate
    
    func didFoundPeer(_ peer: TTTPeer) {
        availablePeers.append(peer)
    }
    
    func didLostPeer(_ peer: TTTPeer) {
        availablePeers.removeAll{$0==peer}
    }
    
    func didReceiveInvitationFrom(_ peer: TTTPeer) {
        availablePeers.updateState(.waitingResponse, forPeer: peer)
        
        if let awaitingPeer = availablePeers.awaitingResponse.first, awaitingPeer == peer {
            alertHandler.showAlert(invitationReceivedAlert(from: peer))
        }
    }
    
    func didConnectTo(_ peer: TTTPeer) {
        game.restart()
        availablePeers.updateState(.connected, forPeer: peer)
        connection?.send(.player, withData: mainPlayer.cloneChangingId(id:3).encode())
        isShowingSettings = false
    }
    
    func didDisconnectFrom(_ peer: TTTPeer, showAlert: Bool) {
        if showAlert {alertHandler.showAlert(connectionLostAlert(for: peer))}
        guestPlayer = LocalPlayer(id: 2)
        game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
        startAdvertising()
    }
    
    func didReceiveDeclineFrom(_ peer: TTTPeer) {
        availablePeers.updateState(.idle, forPeer: peer)
        alertHandler.showAlert(invitationDeclinedAlert(for: peer))
    }
    
    func didReceiveRestart() {
        game.restart()
    }
    
    func didReceivePlayer(_ player: Player) {
        guard let startRemoteGame = startRemoteGame else {return}
        
        guestPlayer = player
        game = startRemoteGame(player)
    }
    
    func didReceiveMove(_ position: BoardPosition) {
        game.choose(position: position, forPlayer: guestPlayer)
    }
    
    func didReceiveMessage(_ message: String, from peer: TTTPeer) {
        alertHandler.showAlert(messageAlert(message, from: peer))
    }
    
    //MARK: - Alerts
    
    private func invitationReceivedAlert(from peer: TTTPeer) -> Alert {
        Alert(
            title: Text("Invitation received."),
            message: Text("\(peer.name) would like to play with you."),
            primaryButton: .default(Text("Decline")) {
                self.respondInvitation(false, forPeer: peer)
            },
            secondaryButton: .default(Text("Accept")) {
                self.respondInvitation(true, forPeer: peer)
            })
    }
    
    private func connectionLostAlert(for peer: TTTPeer? = nil) -> Alert {
        Alert(title: Text("Connection Lost"),
            message:Text("Connection with player \(peer?.name ?? "") was lost."))
    }
    
    private func invitationDeclinedAlert(for peer: TTTPeer) -> Alert {
        Alert(title: Text("Invitation Declined"),
              message:Text("Player \(peer.name) declined your invitation."))
    }
    
    private func messageAlert(_ message: String, from peer: TTTPeer) -> Alert {
        Alert(title: Text("Message Received"),
              message:Text("\(peer.name): \(message)"))
    }
}
