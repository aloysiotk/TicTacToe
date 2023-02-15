//
//  TicTacToeGame.swift
//  TicTacToe
//
//  Created by Aloysio Nandi Tiscoski on 1/24/23.
//

import Foundation
import CoreML

struct TicTacToeGame {
    typealias BoardPosition = Board.BoardPosition
    
    private static let columns = 3
    
    private(set) var player1: Player
    private(set) var player2: Player
    private(set) var board = Board(columns: columns)
    private(set) var matchCount = 0
    private(set) var moveCount = 0
    private var mlModel: TicTacToeClassification?
    var playerInTurn: Player {(matchCount+moveCount)%2 == 0 ? player1 : player2}
    var isGameFinished: Bool {hasWinner || board.isFull}
    
    var hasWinnerOld: Bool {
        let filteredItens = board.itens.filter({$0.owner == playerInTurn})
        let columns = board.columns
        
        if filteredItens.filter({$0.position.h == $0.position.v}).count == columns
            || filteredItens.filter({$0.position.h + $0.position.v == columns-1}).count == columns {
            return true
        } else {
            for i in 0..<columns {
                if filteredItens.filter({$0.position.h == i}).count == columns
                    || filteredItens.filter({$0.position.v == i}).count == columns {
                    return true
                }
            }
        }
        return false
    }
    
    var hasWinner: Bool {
        let i = board.itens.getOwnersId()
        
        do {
            var modelPrediction = try mlModel?.prediction(pos0:i[0], pos1:i[1], pos2:i[2], pos3:i[3], pos4:i[4], pos5:i[5], pos6:i[6], pos7:i[7], pos8:i[8])
            return modelPrediction!.Winner != 0
        } catch {
            return false
        }
    }
    
    init(player1: Player, player2: Player) {
        do {
            self.player1 = player1
            self.player2 = player2
            self.mlModel = try TicTacToeClassification(configuration: MLModelConfiguration())
        } catch {
            print("TicTacToeClassification init error")
        }
    }
    
    @discardableResult mutating func choose(position: BoardPosition, forPlayer player: Player) -> Bool {
        if playerInTurn == player {
            if board.setOwner(player, forPosition: position) {
                if !hasWinner {
                    moveCount += 1
                }
                return true
            }
        }
        return false
    }
    
    mutating func restart() {
        matchCount += isGameFinished ? 1 : 0
        moveCount = 0
        board = Board(columns: TicTacToeGame.columns)
    }
    
    //MARK: -Board
    
    struct Board {
        let columns: Int
        private(set) var itens: [BoardItem]
        var isFull: Bool {itens.filter({$0.owner == nil}).isEmpty}
        
        init(columns: Int) {
            self.columns = columns
            self.itens = []
            
            populateBoardItens()
        }
        
        private mutating func populateBoardItens() {
            for i in 0..<columns*columns {
                let position = BoardPosition(h:i/columns, v:i%columns)
                itens.append(BoardItem(position: position, id:"\(position.h)\(position.v)"))
            }
        }
        
        @discardableResult mutating func setOwner(_ owner: Player, forPosition position: BoardPosition) -> Bool {
            if let index = indexIfPositionAvailable(position) {
                itens[index].owner = owner
                return true
            }
            return false
        }
        
        private func indexIfPositionAvailable(_ position: BoardPosition) -> Int? {
            if let index = itens.firstIndex(where:{$0.position == position}) {
                if itens[index].owner == nil {
                    return index
                }
            }
            return nil
        }
        
        //MARK: -BoardItem
        
        struct BoardItem: Identifiable {
            var owner: Player? = nil
            let position: BoardPosition
            let id: String
            
            init(position: BoardPosition, id: String) {
                self.position = position
                self.id = id
            }
        }
        
        //MARK: -BoardPosition
        
        struct BoardPosition: Equatable, Codable {
            let h: Int
            let v: Int
            
            init(h: Int, v: Int) {
                self.h = h
                self.v = v
            }
            
            init(fromData data: Data) throws {
                self = try JSONDecoder().decode(BoardPosition.self, from: data)
            }

            func encode() -> Data? {
                do {
                    return try JSONEncoder().encode(self)
                } catch {
                    print("Error encoding BoardPosition")
                    return nil
                }
            }
        }
    }
}
