//
//  Player.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/9/23.
//

import Foundation

class Player: Equatable, Codable {
    let id: Int
    var name: String
    var icon: String
    var color: String
    
    init(id: Int, name: String, icon: String, color: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
    
    convenience init(fromData data: Data) throws {
        let player = try JSONDecoder().decode(Player.self, from: data)
        self.init(id: player.id, name: player.name, icon: player.icon, color: player.color)
    }
    
    func encode() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        }catch {
            print("Error encoding Player")
            return nil
        }
    }
    
    func cloneChangingId(id: Int) -> Player {
        return Player(id: id, name: self.name, icon: self.icon, color: self.color)
    }
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}

//MARK: - LocalPlayer

class LocalPlayer: Player {
    override var name: String {didSet { DataHandler.store(data:name, forKey: "Player\(id).name")}}
    override var icon: String {didSet { DataHandler.store(data:icon, forKey: "Player\(id).icon")}}
    override var color: String {didSet { DataHandler.store(data:color, forKey: "Player\(id).color")}}
    
    init (id: Int) {
        let name = DataHandler.retrieve(forKey: "Player\(id).name") ?? "Player \(id)"
        let icon = DataHandler.retrieve(forKey: "Player\(id).icon") ?? String(id)
        let color = DataHandler.retrieve(forKey: "Player\(id).color") ?? "ColorRed"
        
        super.init(id: id, name: name, icon: icon, color: color)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

//MARK: - AutomatedPlayer

class AutomatedPlayer: Player {
    typealias BoardPosition = TicTacToeGame.BoardPosition
    
    func play(board: TicTacToeGame.Board, choose:(BoardPosition)->()) {
        var i: Int
        
        if let x = firstPossibleToWinIndex(board: board) {
            i = x
        } else if let y = firstPossibleToLoseIndex(board: board) {
            i = y
        } else {
            repeat {
                i = Int.random(in: 0..<board.itens.count)
            } while board.itens[i].owner != nil && !board.isFull
        }
        
        choose(board.itens[i].position)
    }
    
    func firstPossibleToWinIndex(board: TicTacToeGame.Board) -> Int? {
        let mineMoves = board.itens.filter({$0.owner == self})
        let oponentMoves = board.itens.filter({$0.owner != self && $0.owner != nil})
        let columns = board.columns - 1
        
        if mineMoves.filter({$0.position.h == $0.position.v}).count == columns
            && oponentMoves.filter({$0.position.h == $0.position.v}).count == 0 {
            return board.itens.firstIndex(where: {$0.position.h == $0.position.v && $0.owner == nil})
        } else if mineMoves.filter({$0.position.h + $0.position.v == columns}).count == columns
                    && oponentMoves.filter({$0.position.h + $0.position.v == columns}).count == 0{
            return board.itens.firstIndex(where: {$0.position.h + $0.position.v == columns && $0.owner == nil})
        } else {
            for i in 0...columns {
                if mineMoves.filter({$0.position.h == i}).count == columns
                    && oponentMoves.filter({$0.position.h == i}).count == 0 {
                    return board.itens.firstIndex(where: {$0.position.h == i && $0.owner == nil})
                } else if mineMoves.filter({$0.position.v == i}).count == columns
                            && oponentMoves.filter({$0.position.v == i}).count == 0 {
                    return board.itens.firstIndex(where: {$0.position.v == i && $0.owner == nil})
                }
            }
        }
        return nil
    }
    
    func firstPossibleToLoseIndex(board: TicTacToeGame.Board) -> Int? {
        let mineMoves = board.itens.filter({$0.owner == self})
        let oponentMoves = board.itens.filter({$0.owner != self && $0.owner != nil})
        let columns = board.columns - 1
        
        if mineMoves.filter({$0.position.h == $0.position.v}).count == 0
            && oponentMoves.filter({$0.position.h == $0.position.v}).count == columns {
            return board.itens.firstIndex(where: {$0.position.h == $0.position.v && $0.owner == nil})
        } else if mineMoves.filter({$0.position.h + $0.position.v == columns}).count == 0
                    && oponentMoves.filter({$0.position.h + $0.position.v == columns}).count == columns{
            return board.itens.firstIndex(where: {$0.position.h + $0.position.v == columns && $0.owner == nil})
        } else {
            for i in 0...columns {
                if mineMoves.filter({$0.position.h == i}).count == 0
                    && oponentMoves.filter({$0.position.h == i}).count == columns {
                    return board.itens.firstIndex(where: {$0.position.h == i && $0.owner == nil})
                } else if mineMoves.filter({$0.position.v == i}).count == 0
                            && oponentMoves.filter({$0.position.v == i}).count == columns {
                    return board.itens.firstIndex(where: {$0.position.v == i && $0.owner == nil})
                }
            }
        }
        return nil
    }
}
