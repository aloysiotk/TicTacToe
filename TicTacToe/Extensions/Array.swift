//
//  Extensions.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import Foundation
import SwiftUI

extension Array where Element: Equatable {
    mutating func appendIfNotMember(_ newElement: Element) {
        if self.filter({$0==newElement}).isEmpty {
            self.append(newElement)
        }
    }
}

extension Array<TTTPeer> {
    var awaitingResponse: [TTTPeer] {self.filter({$0.state == .waitingResponse}).sorted(by:{$0.lastStateChange < $1.lastStateChange})}
    
    mutating func updateState(_ state: TTTPeer.MCCPeerState, forPeer peer: TTTPeer) {
        if let peerIndex = self.firstIndex(where:{$0 == peer}) {
            self[peerIndex].state = state
        }
    }
}

extension Array where Element: Identifiable {
    func element(by id: Element.ID) -> Element? {
        self.first(where: {$0.id == id})
    }
}

extension Array<TTTConnector.Invitation> {
    mutating func removePeer(_ peer: TTTPeer) -> TTTConnector.Invitation? {
        guard let peerIndex = self.firstIndex(where:{$0.peer.hash == peer.id}) else {return nil}
        return self.remove(at: peerIndex)
    }
}

extension Array<BoardItem> {
    func ownersIds() -> [Double] {
        return self.map({Double($0.owner?.id ?? 0)})
    }
}
