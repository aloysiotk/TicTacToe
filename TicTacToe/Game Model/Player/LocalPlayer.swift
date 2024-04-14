//
//  LocalPlayer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 4/4/24.
//

import Foundation

class LocalPlayer: Player {
    override var name: String {didSet { DataHandler.store(data:name, forKey: .playerName, andId: id)}}
    override var color: PlayerColors {didSet { DataHandler.store(data:color.rawValue, forKey: .playerColor, andId: id)}}
    override var icon: String {didSet { DataHandler.store(data:icon, forKey: .playerIcon, andId: id)
                                        if icon.count > 1 {icon = String(icon.suffix(1))}
                                        }}
    
    init (id: Int) {
        let name = DataHandler.retrieve(forKey: .playerName, andId: id) ?? "Player \(id)"
        let icon = DataHandler.retrieve(forKey: .playerIcon, andId: id) ?? String(id)
        let color = PlayerColors(rawValue: DataHandler.retrieve(forKey: .playerColor, andId: id) ?? "red") ?? .red
        
        super.init(id: id, name: name, icon: icon, color: color)
    }
    
    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)
    }
}
