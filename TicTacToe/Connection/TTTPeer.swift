//
//  TTTPeer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 4/1/24.
//

import Foundation

struct TTTPeer: Equatable, Identifiable {
    let id : Int
    let name : String
    var state: MCCPeerState = .idle {didSet {lastStateChange = Date()}}
    private(set) var lastStateChange = Date()
    
    enum MCCPeerState {
        case idle
        case waitingResponse
        case connecting
        case connected
    }
    
    static func == (lhs: TTTPeer, rhs: TTTPeer) -> Bool {
        return lhs.id == rhs.id
    }
}
