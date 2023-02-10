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
