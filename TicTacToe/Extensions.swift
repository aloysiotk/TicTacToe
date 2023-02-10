//
//  Extensions.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/3/23.
//

import Foundation
import SwiftUI

extension Array where Element: Equatable{
    mutating func appendIfNotMember(_ newElement: Element) {
        if self.filter({$0==newElement}).isEmpty {
            self.append(newElement)
        }
    }
}

extension Array<MCConnector.MCCPeer> {
    mutating func updateState(_ state:MCConnector.MCCPeer.MCCPeerState, forPeer peer: MCConnector.MCCPeer) {
        if let peerIndex = self.firstIndex(where:{$0 == peer}) {
            self[peerIndex].state = state
        }
    }
}

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

extension Player {
    func bindingName() -> Binding<String> {
        Binding(
            get: {self.name},
            set: { self.name = $0 }
        )
    }
    
    func bindingColor() -> Binding<String> {
        Binding(
            get: {self.color},
            set: { self.color = $0 }
        )
    }
    
    func bindingIcon() -> Binding<String> {
        Binding(
            get: {self.icon},
            set: { self.icon = $0 }
        )
    }
}
