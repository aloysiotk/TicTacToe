//
//  DumbPlayer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 4/4/24.
//

import Foundation

class DumbPlayer: Player {
    override func play(game: TicTacToeGame, choose:(BoardPosition)->()) {
        var i: Int
        
        if let x = firstPossibleToWinIndex(board: game.board) {
            i = x
        } else if let y = firstPossibleToLoseIndex(board: game.board) {
            i = y
        } else {
            repeat {
                i = Int.random(in: 0..<game.board.items.count)
            } while game.board.items[i].owner != nil && !game.board.isFull
        }
        
        choose(game.board.items[i].position)
    }
    
    func firstPossibleToWinIndex(board: Board) -> Int? {
        let mineMoves = board.items.filter({$0.owner == self})
        let opponentMoves = board.items.filter({$0.owner != self && $0.owner != nil})
        let columns = board.columns - 1
        
        if mineMoves.filter({$0.position.h == $0.position.v}).count == columns
            && opponentMoves.filter({$0.position.h == $0.position.v}).count == 0 {
            return board.items.firstIndex(where: {$0.position.h == $0.position.v && $0.owner == nil})
        } else if mineMoves.filter({$0.position.h + $0.position.v == columns}).count == columns
                    && opponentMoves.filter({$0.position.h + $0.position.v == columns}).count == 0{
            return board.items.firstIndex(where: {$0.position.h + $0.position.v == columns && $0.owner == nil})
        } else {
            for i in 0...columns {
                if mineMoves.filter({$0.position.h == i}).count == columns
                    && opponentMoves.filter({$0.position.h == i}).count == 0 {
                    return board.items.firstIndex(where: {$0.position.h == i && $0.owner == nil})
                } else if mineMoves.filter({$0.position.v == i}).count == columns
                            && opponentMoves.filter({$0.position.v == i}).count == 0 {
                    return board.items.firstIndex(where: {$0.position.v == i && $0.owner == nil})
                }
            }
        }
        return nil
    }
    
    func firstPossibleToLoseIndex(board: Board) -> Int? {
        let mineMoves = board.items.filter({$0.owner == self})
        let opponentMoves = board.items.filter({$0.owner != self && $0.owner != nil})
        let columns = board.columns - 1
        
        if mineMoves.filter({$0.position.h == $0.position.v}).count == 0
            && opponentMoves.filter({$0.position.h == $0.position.v}).count == columns {
            return board.items.firstIndex(where: {$0.position.h == $0.position.v && $0.owner == nil})
        } else if mineMoves.filter({$0.position.h + $0.position.v == columns}).count == 0
                    && opponentMoves.filter({$0.position.h + $0.position.v == columns}).count == columns{
            return board.items.firstIndex(where: {$0.position.h + $0.position.v == columns && $0.owner == nil})
        } else {
            for i in 0...columns {
                if mineMoves.filter({$0.position.h == i}).count == 0
                    && opponentMoves.filter({$0.position.h == i}).count == columns {
                    return board.items.firstIndex(where: {$0.position.h == i && $0.owner == nil})
                } else if mineMoves.filter({$0.position.v == i}).count == 0
                            && opponentMoves.filter({$0.position.v == i}).count == columns {
                    return board.items.firstIndex(where: {$0.position.v == i && $0.owner == nil})
                }
            }
        }
        return nil
    }
}
