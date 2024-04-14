//
//  Board.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 3/26/24.
//

import Foundation

struct Board {
    let columns: Int
    private(set) var items = [BoardItem]()
    var isFull: Bool {items.filter({$0.owner == nil}).isEmpty}
    
    init(columns: Int) {
        self.columns = columns
        populateBoardItems()
    }
    
    private mutating func populateBoardItems() {
        for i in 0..<columns*columns {
            let position = BoardPosition(h:i/columns, v:i%columns)
            items.append(BoardItem(position: position, id:"\(position.h)\(position.v)"))
        }
    }
    
    @discardableResult mutating func populate(position: BoardPosition, withPlayer player: Player, atTurn turn: Int) -> Bool {
        if let index = items.firstIndex(where:{$0.position == position}) {
            return items[index].populate(with: player, atTurn: turn)
        }
        return false
    }
}
