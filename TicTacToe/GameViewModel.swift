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
    typealias BoardItem = TicTacToeGame<Player>.BoardItem
    typealias MCCPeer = MCConnector.MCCPeer
    
    @Published var model: TicTacToeGame<Player> = TicTacToeGame(columns: 3, player1: LocalPlayer(id: 1), player2: LocalPlayer(id: 2))
    @Published var availablePeers: [MCCPeer] = []
    @Published var isMultipeerOn = false {didSet{toogledMultipeer()}}
    @Published var isShowingInvitation = false
    @Published var isShowingAlert = false
    
    var isConnecting: Bool {!availablePeers.filter({$0.state == .connecting}).isEmpty}
    
    @Published var isMyTurn = true
    
    private var connection: MCConnector?
    var cards: [BoardItem] {model.board}
    var playerInTurn: Player {model.playerInTurn}
    var columns: Int {model.columns}
    var gameFinished: Bool {model.gameFinished}
    var hasWinner: Bool {model.hasWinner}
    var firstPendingInvitation: MCCPeer? {availablePeers.first(where:{$0.state == .waitingResponse})}
    
    init() {
        isMultipeerOn = DataHandler.retrieve(forKey: "IsMultipeerOn") ?? false
        //Change logic to only start advertising when on settings view or receive invitation here
        connection?.stopAdvertising()
    }
    
    func toogledMultipeer() {
        DataHandler.store(data: isMultipeerOn, forKey: "IsMultipeerOn")
        model = TicTacToeGame(columns: 3, player1: LocalPlayer(id: 1), player2: LocalPlayer(id: 2))
        
        if isMultipeerOn {
            if connection == nil {
                availablePeers = []
                connection = MCConnector(withPublicName: model.player1.name)
                connection?.delegate = self
                connection?.startAdvertising()
            }
        } else {
            connection?.stopAdvertising()
            availablePeers = []
            connection = nil
            isMyTurn = true
        }
    }
    
    func startANewGame() {
        if let connection = connection {
            connection.send(key: .restart, withData: nil)
            connection.send(key: .message, withData: "Teste... 1, 2, 3... Testando... 1,2,3...".encode())
        }
        model.startANewGame()
    }
    
    func choose(boardItem: BoardItem) -> Bool {
        if let connection = connection {
            if connection.isConnected {
                if isMyTurn {
                        isMyTurn = false
                        model.choose(boardItem: boardItem)
                        sendMove(item:boardItem)
                        return true
                }
            } else {
                isShowingAlert = true
            }
            return false
        } else {
            return model.choose(boardItem: boardItem)
        }
    }
    
    func startAdvertising() {
        connection?.startAdvertising()
    }
    
    func stopAdvertising() {
        connection?.stopAdvertising()
        availablePeers = []
    }
    
    func invitePeer(_ peer: MCCPeer) {
        if let peerIndex = availablePeers.firstIndex(where:{$0.id == peer.id}) {
            availablePeers[peerIndex].state = .connecting
        }
        
        connection?.invitePeer(peer)
    }
    
    func invitationResponse(_ response: Bool, forPeer peer: MCCPeer) {
        if let peerIndex = availablePeers.firstIndex(where:{$0.id == peer.id}) {
            availablePeers[peerIndex].state = .connecting
        }
        
        connection?.respondInvitationFor(peer, withValue: response)
        
        if response {
            for i in 0..<(availablePeers.count) {
                if availablePeers[i].state == .waitingResponse {
                    availablePeers[i].state = .idle
                }
            }
        } else if firstPendingInvitation != nil {
            isShowingInvitation = true
        }
        
        isMyTurn = false
        model.isGuest = true
    }
    
    func sendMove(item: BoardItem) {
        connection?.send(key: .move, withData: item.encode())
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
        connection?.send(key: .player, withData: model.player1.cloneChangingId(id:2).encode())
    }
    
    func didDisconnect() {
        print("GameViewModel didDisconnect not handled")
    }
    
    func didReceiveStartANewGame() {
        model.startANewGame()
    }
    
    func didRecievePlayer(_ player: Player) {
        model.player2 = player
    }
    
    func didRecieveMove(_ boardItem: TicTacToeGame<Player>.BoardItem) {
        model.choose(boardItem: boardItem)
        isMyTurn = true
    }
}
