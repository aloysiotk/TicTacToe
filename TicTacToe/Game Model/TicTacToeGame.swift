//
//  TicTacToeGame.swift
//  TicTacToe
//
//  Created by Aloysio Nandi Tiscoski on 1/24/23.
//

import Foundation
import CoreML

struct TicTacToeGame {
    private static let columns = 3
    
    let player1: Player
    let player2: Player
    private(set) var board = Board(columns: columns)
    private(set) var matchCount = 0
    private(set) var  turnCount = 0
    private var mlModel: TicTacToeClassification?
    var playerInTurn: Player {(matchCount + turnCount) % 2 == 0 ? player1 : player2}
    var isGameFinished: Bool {hasWinner || board.isFull}
    
    var hasWinner: Bool {
        let filteredItems = board.items.filter({$0.owner == playerInTurn})
        let columns = board.columns
        
        if filteredItems.filter({$0.position.h == $0.position.v}).count == columns
            || filteredItems.filter({$0.position.h + $0.position.v == columns-1}).count == columns {
            return true
        } else {
            for i in 0..<columns {
                if filteredItems.filter({$0.position.h == i}).count == columns
                    || filteredItems.filter({$0.position.v == i}).count == columns {
                    return true
                }
            }
        }
        return false
    }
    
    var hasWinnerML: Bool {
        let i = board.items.ownersIds()
        do {
            let modelPrediction = try mlModel?.prediction(pos0:i[0], pos1:i[1], pos2:i[2], pos3:i[3], pos4:i[4],
                                                          pos5:i[5], pos6:i[6], pos7:i[7], pos8:i[8])
            return modelPrediction!.Winner != 0
        } catch {return false}
    }
    
    init(player1: Player, player2: Player) {
        self.player1 = player1
        self.player2 = player2
        
        ///To use ML uncomment the following mlModel init and replace the use of the var hasWinner to hasWinnerML at the function choose and the var isGameFinished
//        do {
//            self.mlModel = try TicTacToeClassification(configuration: MLModelConfiguration())
//        } catch {
//            fatalError("TicTacToeGame - Unable to init mlModel")
//        }
    }
    
    @discardableResult mutating func choose(position: BoardPosition, forPlayer player: Player) -> Bool {
        if playerInTurn == player {
            if board.populate(position: position, withPlayer: player, atTurn: turnCount) {
                if !hasWinner {
                    turnCount += 1
                }
                return true
            }
        }
        return false
    }
    
    mutating func restart() {
        matchCount += isGameFinished ? 1 : 0
        turnCount = 0
        board = Board(columns: TicTacToeGame.columns)
    }
}
