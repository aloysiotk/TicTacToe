//
//  DataStorer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import Foundation


struct DataHandler {
    static func store(data: Bool, forKey key: String) {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: "TTTGame" + key)
    }
    
    static func retrieve(forKey key: String) -> Bool? {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: "TTTGame" + key)
    }
    
    static func store(data: String, forKey key: String) {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: "TTTGame" + key)
    }
    
    static func retrieve(forKey key: String) -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "TTTGame" + key)
    }
}
