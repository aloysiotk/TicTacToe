//
//  String.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 4/2/24.
//

import Foundation

extension String {
    init(fromData data: Data) throws {
        self = try JSONDecoder().decode(String.self, from: data)
    }
    
    func encode() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            print("Error encoding String")
            return nil
        }
    }
}
