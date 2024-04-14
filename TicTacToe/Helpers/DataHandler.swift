//
//  DataStorer.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import Foundation

struct DataHandler {
    static private let appKey = "TTTGame-"
    static private let defaults = UserDefaults.standard
    
    static func store(data: Any?, forKey key: DataKey, andId id: Int? = nil) {
        defaults.set(data, forKey: fullKey(forKey: key, andId: id))
    }
    
    static func retrieve(forKey key: DataKey, andId id: Int? = nil) -> Bool {
        return defaults.bool(forKey: fullKey(forKey: key, andId: id))
    }
    
    static func retrieve(forKey key: DataKey, andId id: Int? = nil) -> String? {
        return defaults.string(forKey: fullKey(forKey: key, andId: id))
    }
    
    static func retrieve(forKey key: DataKey, andId id: Int? = nil) -> Int? {
        if keyExists(key) {
            return defaults.integer(forKey: fullKey(forKey: key, andId: id))
        } else {
            return nil
        }
    }
    
    private static func fullKey(forKey key: DataKey, andId id: Int? = nil) -> String {
        appKey + key.rawValue + (id == nil ? "" : String(id!))
    }
    
    private static func keyExists(_ key: DataKey, andId id: Int? = nil) -> Bool {
        defaults.object(forKey: fullKey(forKey: key, andId: id)) != nil
    }
    
    enum DataKey: String {
        case isMultiPeerOn
        case automatedPlayerSelectedId
        case playerName
        case playerIcon
        case playerColor
    }
}
