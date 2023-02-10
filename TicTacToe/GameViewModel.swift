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
    
    @Published private(set) var game: TicTacToeGame?
    private var connection: MCConnector?
    private var startRemoteGame: ((Player) -> TicTacToeGame)?
    @Published var mainPlayer: LocalPlayer = LocalPlayer(id: 1)
    @Published var guestPlayer: Player?
    
    @Published var guestPlayerName: String?
    
    @Published var availablePeers: [MCCPeer] = []
    @Published var isMultipeerOn = false {didSet{toogledMultipeer()}}
    @Published var isShowingInvitation = false
    @Published var isShowingAlert = false
    @Published var isShowingSettings = false
    
    var isConnecting: Bool {!availablePeers.filter({$0.state == .connecting}).isEmpty}
    var boardItens: [Board.BoardItem] {game?.board.itens ?? []}
    var columns: Int {game?.board.columns ?? 3}
    var playerInTurnName: String {game?.playerInTurn.name ?? "No player connected..."}
    var playerInTurnColor: String {game?.playerInTurn.color ?? "ColorBlue"}
    var isGameFinished: Bool {game?.isGameFinished ?? false}
    var hasWinner: Bool {game?.hasWinner ?? false}
    //TODO: Timestamp on MCCPeer to sort pending invitations
    var firstPendingInvitation: MCCPeer? {availablePeers.first(where:{$0.state == .waitingResponse})}
    
    init() {
        isMultipeerOn = DataHandler.retrieve(forKey: "IsMultipeerOn") ?? false
    }
    
    func toogledMultipeer() {
        DataHandler.store(data: isMultipeerOn, forKey: "IsMultipeerOn")
        
        if isMultipeerOn {
            game = nil
            connection = MCConnector(withPublicName: mainPlayer.name, andDelegate: self)
            startAdvertising()
        } else {
            stopAdvertising()
            connection = nil
            guestPlayer = LocalPlayer(id: 2)
            game = TicTacToeGame(player1: mainPlayer, player2: guestPlayer!)
        }
    }
    
    func restart() {
        if game != nil {
            game!.restart()
            
            if let connection = connection, connection.isConnected  {
                connection.send(.restart, withData: nil)
            }
        }
    }
    
    func choose(position: BoardPosition) -> Bool {
        if let connection = connection {
            if connection.isConnected  {
                if connection.isConnected {
                    if game != nil {
                        connection.send(.move, withData: position.encode())
                        return game!.choose(position: position, forPlayer:mainPlayer)
                    }
                }
            } else {
                isShowingAlert = true
            }
            return false
        } else {
            if game != nil {
                return game!.choose(position: position, forPlayer: game!.playerInTurn)
            }
        }
        return false
    }
    
    func startAdvertising() {
        //availablePeers = []
        connection?.startAdvertising()
    }
    
    func stopAdvertising() {
        connection?.stopAdvertising()
        availablePeers = []
    }
    
    func invitePeer(_ peer: MCCPeer) {
        availablePeers.updateState(.connecting, forPeer: peer)
        connection?.invitePeer(peer)
        startRemoteGame = newGameAsPlayer1(player2:)
    }
    
    func respondInvitation(_ response: Bool, forPeer peer: MCCPeer) {
        // TODO: Allow receive invitation on GameView
        
        if response == true {
            let pendingPeers = availablePeers.filter{$0.state == .waitingResponse}
            for pendingPeer in pendingPeers {
                availablePeers.updateState(peer == pendingPeer ? .connecting : .idle, forPeer: pendingPeer)
                connection?.respondInvitationFor(pendingPeer, withValue: peer == pendingPeer)
                startRemoteGame = newGameAsPlayer2(player1:)
            }
        } else {
            availablePeers.updateState(.idle, forPeer: peer)

            if firstPendingInvitation != nil {
                isShowingInvitation = true
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
        if let peerIndex = self.availablePeers.firstIndex(where:{$0.id == peer.id}) {
            self.availablePeers[peerIndex].state = .waitingResponse
        }
        self.isShowingInvitation = true
    }
    
    func didConnectTo(_ peer: MCCPeer) {
        if let peerIndex = availablePeers.firstIndex(where:{$0.id == peer.id}) {
            availablePeers[peerIndex].state = .connected
        }
        connection?.send(.player, withData: mainPlayer.cloneChangingId(id:2).encode())
        
        isShowingSettings = false
    }
    
    func didDisconnect() {
        print("GameViewModel didDisconnect not handled")
    }
    
    func didReceiveRestart() {
        game?.restart()
    }
    
    func didRecievePlayer(_ player: Player) {
        guestPlayer = player
        game = startRemoteGame!(player)
    }
    
    func didRecieveMove(_ position: BoardPosition) {
        game?.choose(position: position, forPlayer: guestPlayer!)
    }
}
