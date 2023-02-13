//
//  GameViewModel.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import Foundation
import UIKit
import SwiftUI

class GameViewModel: ObservableObject, MCConnectorDelegate {
    typealias Board = TicTacToeGame.Board
    typealias BoardPosition = TicTacToeGame.BoardPosition
    typealias MCCPeer = MCConnector.MCCPeer
    
    
    private var connection: MCConnector?
    private var startRemoteGame: ((Player) -> TicTacToeGame)?
    
    @Published private(set) var game: TicTacToeGame
    @Published var mainPlayer: LocalPlayer
    @Published var guestPlayer: Player
    @Published var availablePeers: [MCCPeer] = []
    @Published var isMultiplayer = false {didSet{toogledMultiplayer()}}
    @Published var isShowingAlert = false
    @Published var isShowingSettings = false
    
    var alert: (()->Alert)?
    
    var boardItens: [Board.BoardItem] {game.board.itens}
    var columns: Int {game.board.columns}
    var playerInTurnName: String {game.playerInTurn.name}
    var playerInTurnColor: String {game.playerInTurn.color}
    var isGameFinished: Bool {game.isGameFinished}
    var hasWinner: Bool {game.hasWinner}
    var isConnecting: Bool {!availablePeers.filter({$0.state == .connecting}).isEmpty}
    var isConnected: Bool {connection?.isConnected ?? false}
    var firstPendingInvitation: MCCPeer? {availablePeers.filter({$0.state == .waitingResponse}).sorted(by:{$0.lastStateChange < $1.lastStateChange}).first}
    
    init() {
        let mainPlayer = LocalPlayer(id: 1)
        let guestPlayer = LocalPlayer(id: 2)
        
        self.mainPlayer = mainPlayer
        self.guestPlayer = guestPlayer
        self.game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
        self.isMultiplayer = DataHandler.retrieve(forKey: "IsMultipeerOn") ?? false
    }
    
    private func toogledMultiplayer() {
        DataHandler.store(data: isMultiplayer, forKey: "IsMultipeerOn")
        
        if isMultiplayer {
            guestPlayer = LocalPlayer(id: 2)
            game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
            connection = MCConnector(withPublicName: mainPlayer.name, andDelegate: self)
            startAdvertising()
        } else {
            stopAdvertising()
            connection = nil
            //TODO: Start automated player
            guestPlayer = AutomatedPlayer(id: 3, name: "Easy", icon: "@", color: "ColorRed")
            game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
        }
    }
    
    func restart() {
        game.restart()
        
        if let connection = connection, connection.isConnected  {
            connection.send(.restart, withData: nil)
        } else if !isMultiplayer && game.playerInTurn == guestPlayer {
            (guestPlayer as! AutomatedPlayer).play(board: game.board, choose: automatedMove(position:))
        }
    }
    
    func choose(position: BoardPosition) -> Bool {
        if isConnected || !isMultiplayer {
            let isValidMove = game.choose(position: position, forPlayer:mainPlayer)
            
            if isValidMove {
                if isConnected {
                    connection!.send(.move, withData: position.encode())
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        (self.guestPlayer as! AutomatedPlayer).play(board: self.game.board,
                                                                    choose: self.automatedMove(position:))
                    }
                }
            }
            return isValidMove
        } else {
            return game.choose(position: position, forPlayer: game.playerInTurn)
            
        }
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
    
    func peerTouched(_ peer: MCCPeer) -> Bool {
        if peer.state == .idle && (!isConnecting && !isConnected) {
            invitePeer(peer)
            return true
        } else if peer.state == .connected {
            disconnect()
            return true
        }
        return false
    }
    
    private func invitePeer(_ peer: MCCPeer) {
        availablePeers.updateState(.connecting, forPeer: peer)
        connection?.invitePeer(peer)
        startRemoteGame = newGameAsPlayer1(player2:)
    }
    
    private func disconnect() {
        connection?.disconnect()
    }
    
    func respondInvitation(_ response: Bool, forPeer peer: MCCPeer) {
        if response {
            let pendingPeers = availablePeers.filter{$0.state == .waitingResponse}
            for pendingPeer in pendingPeers {
                availablePeers.updateState(peer == pendingPeer ? .connecting : .idle, forPeer: pendingPeer)
                connection?.respondInvitationFor(pendingPeer, withValue: peer == pendingPeer)
                startRemoteGame = newGameAsPlayer2(player1:)
            }
        } else {
            availablePeers.updateState(.idle, forPeer: peer)
            connection?.respondInvitationFor(peer, withValue: response)
            
            if firstPendingInvitation != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showAlert(self.invitationRecievedAlert)
                }
            }
        }
    }
    
    private func newGameAsPlayer1(player2: Player) -> TicTacToeGame {
        return TicTacToeGame(player1: mainPlayer, player2: player2)
    }
    
    private func newGameAsPlayer2(player1: Player) -> TicTacToeGame {
        return TicTacToeGame(player1: player1, player2: mainPlayer)
    }
    
    //MARK: - MCConnectorDelegate
    
    func didFoundPeer(_ peer: MCCPeer) {
        availablePeers.append(peer)
    }
    
    func didLostPeer(_ peer: MCCPeer) {
        availablePeers.removeAll{$0==peer}
    }
    
    func didRecieveInvitationFrom(_ peer: MCCPeer) {
        availablePeers.updateState(.waitingResponse, forPeer: peer)
        showAlert(invitationRecievedAlert)
    }
    
    func didConnectTo(_ peer: MCCPeer) {
        game.restart()
        availablePeers.updateState(.connected, forPeer: peer)
        connection?.send(.player, withData: mainPlayer.cloneChangingId(id:2).encode())
        isShowingSettings = false
    }
    
    func didDisconnectFrom(_ peer: MCCPeer, showAlert: Bool) {
        if showAlert {self.showAlert(connectionLostAlert)}
        guestPlayer = LocalPlayer(id: 2)
        game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer)
        startAdvertising()
    }
    
    func didRecieveDeclineFrom(_ peer: MCCPeer) {
        availablePeers.updateState(.idle, forPeer: peer)
        self.showAlert(invitationDeclinedAlert)
    }
    
    func didReceiveRestart() {
        game.restart()
    }
    
    func didRecievePlayer(_ player: Player) {
        guestPlayer = player
        game = startRemoteGame!(player)
    }
    
    func didRecieveMove(_ position: BoardPosition) {
        game.choose(position: position, forPlayer: guestPlayer)
    }
    
    //MARK: - Alerts
    
    func showAlert(_ alert: @escaping ()->Alert) {
        self.alert = alert
        isShowingAlert = true
    }
    
    func invitationRecievedAlert() -> Alert {
        if let peer = firstPendingInvitation {
            return Alert(
                title: Text("Invitation received."),
                message: Text("\(peer.name) would like to play with you."),
                primaryButton: .default(Text("Decline")) {
                    self.respondInvitation(false, forPeer: peer)
                },
                secondaryButton: .default(Text("Accept")) {
                    self.respondInvitation(true, forPeer: peer)
                }
            )
        } else {
            isShowingAlert = false
            return Alert(title: Text("Connection lost."))
        }
    }
    
    func connectionLostAlert() -> Alert {
        return Alert(title: Text("Connection Lost"),
                     message:Text("Connection with remote peer was lost."))
    }
    
    func invitationDeclinedAlert() -> Alert {
        return Alert(title: Text("Invitationn Declined."),
                     message:Text("Remote peer declined your invitation."))
    }
}
