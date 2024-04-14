//
//  BoardItem.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 3/26/24.
//

import Foundation

struct BoardItem: Identifiable {
    var owner: Player? = nil
    var populatedAtTurn: Int?
    let position: BoardPosition
    let id: String
    
    init(position: BoardPosition, id: String) {
        self.position = position
        self.id = id
    }
    
    @discardableResult mutating func populate(with player: Player, atTurn turn: Int) -> Bool {
        if owner == nil {
            self.owner = player
            self.populatedAtTurn = turn
            return true
        }
        return false
    }
}
