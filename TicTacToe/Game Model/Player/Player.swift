//
//  Player.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/9/23.
//

import Foundation

class Player: Equatable, Codable, Identifiable {
    let id: Int
    var name: String
    var icon: String
    var color: PlayerColors
    
    init(id: Int, name: String, icon: String, color: PlayerColors) {
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
    
    func play(game: TicTacToeGame, choose:(BoardPosition)->()) {
    }
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}

enum PlayerColors: String, CaseIterable, Codable {
    case red
    case yellow
    case green
    case blue
    case pink
    case purple
    case orange
}
