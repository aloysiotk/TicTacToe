//
//  BoardPosition.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 3/26/24.
//

import Foundation

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
