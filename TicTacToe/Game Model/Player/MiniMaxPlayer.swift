//
//  MiniMaxPlayer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 4/4/24.
//

import Foundation

class MiniMaxPlayer: Player {
    enum CodingKeys: CodingKey {
        case depth
    }
    
    var depth: Int
    
    init(id: Int, name: String, icon: String, color: PlayerColors, depth: Int) {
        self.depth = depth
        super.init(id: id, name: name, icon: icon, color: color)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.depth = try container.decode(Int.self, forKey: .depth)
        try super.init(from: decoder)
    }
    
    override func play(game: TicTacToeGame, choose:(BoardPosition)->()) {
        var position: BoardPosition = BoardPosition(h: -1, v: -1)
        minimax(game: game, depth: depth, alpha: Int.min, beta: Int.max, isMax: true, isFirstLevel: true, position: &position)
        choose(position)
    }
    
    @discardableResult func minimax(game: TicTacToeGame, depth: Int, alpha: Int, beta: Int, isMax: Bool, isFirstLevel: Bool, position: inout BoardPosition) -> Int {
        var alpha = alpha, beta = beta, bestScore = isMax ? Int.min : Int.max
        
        if depth == 0 || game.isGameFinished {
            return getScore(game: game) * depth
        }
        
        for item in game.board.items.shuffled() {
            if item.owner == nil {
                var game = game
                game.choose(position: item.position, forPlayer: game.playerInTurn)
                let branchScore = minimax(game: game, depth: depth-1, alpha: alpha, beta: beta, isMax: !isMax, isFirstLevel: false, position: &position)
                if isMax {
                    alpha = max(alpha, branchScore)
                    if bestScore < branchScore {
                        bestScore = branchScore
                        if isFirstLevel {
                            position = item.position
                        }
                    }
                } else {
                    beta = min(beta, branchScore)
                    if bestScore > branchScore {
                        bestScore = branchScore
                        if isFirstLevel {
                            position = item.position
                        }
                    }
                }
                
                if beta <= alpha {
                    break
                }
            }
        }
        return bestScore
    }
    
    func getScore(game: TicTacToeGame) -> Int {
        if game.hasWinner {
            return 10 * (game.playerInTurn == self ? 1 : -1)
        } else {
           return 0
        }
    }
}
