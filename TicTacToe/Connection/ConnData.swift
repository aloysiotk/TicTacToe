//
//  ConnData.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 4/1/24.
//

import Foundation

struct ConnData: Codable {
    var key: ConnDataKey
    var data: Data?
    
    init(key: ConnDataKey, data: Data?) {
        self.key = key
        self.data = data
    }
    
    init(fromData data: Data) throws {
        self = try JSONDecoder().decode(ConnData.self, from: data)
    }
    
    func encode() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    enum ConnDataKey: Codable {
        case player
        case move
        case restart
        case message
    }
}
