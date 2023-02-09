//
//  TicTacToeGame.swift
//  TicTacToe
//
//  Created by Aloysio Nandi Tiscoski on 1/24/23.
//

import Foundation

struct TicTacToeGame<SomePlayer> where SomePlayer: Equatable, SomePlayer:Codable {
    let columns: Int
    var player1: SomePlayer
    var player2: SomePlayer
    private(set) var board: [BoardItem] = []
    private(set) var matchCount = 0
    private(set) var moveCount = 0
    var playerInTurn : SomePlayer {(matchCount+moveCount)%2 == (isGuest ? 1 : 0) ? player1 : player2}
    var gameFinished: Bool {hasWinner || board.filter({$0.owner == nil}).isEmpty}
    
    //Change this logic
    var isGuest = false
    //
    
    var hasWinner : Bool {
        let filteredCards = board.filter({$0.owner == playerInTurn})
        
        if filteredCards.filter({$0.hPosition == $0.vPosition}).count == columns
            || filteredCards.filter({$0.hPosition + $0.vPosition == columns-1}).count == columns {
            return true
        } else {
            for i in 0..<columns {
                if filteredCards.filter({$0.owner == playerInTurn && $0.hPosition == i}).count == columns
                    || filteredCards.filter({$0.owner == playerInTurn && $0.vPosition == i}).count == columns {
                    return true
                }
            }
        }
        return false
    }
    
    init(columns: Int, player1: SomePlayer, player2: SomePlayer) {
        self.columns = columns
        self.player1 = player1
        self.player2 = player2
        
        populateBoard()
    }
    
    @discardableResult mutating func choose(boardItem: BoardItem) -> Bool {
        if let chosenIndex = board.firstIndex(where: {$0.id == boardItem.id}) {
            if board[chosenIndex].owner == nil {
                board[chosenIndex].owner = playerInTurn
                if !gameFinished  {
                    moveCount += 1
                }
                return true
            }
        }
        return false
    }
    
    mutating func startANewGame () {
        matchCount += gameFinished ? 1 : 0
        moveCount = 0
        board = []
        populateBoard()
    }
    
    mutating func populateBoard() {
        for i in 0..<columns*columns {
            board.append(BoardItem(hPosition: i/columns, vPosition: i%columns, id:"\(i/columns)\(i%columns)"))
        }
    }
    
    //MARK: -Card
    
    struct BoardItem: Identifiable, Codable {
        var owner: SomePlayer? = nil
        let hPosition: Int
        let vPosition: Int
        let id: String
        
        init(hPosition: Int, vPosition: Int, id: String) {
            self.hPosition = hPosition
            self.vPosition = vPosition
            self.id = id
        }
        
        init(fromData data: Data) throws {
            self = try JSONDecoder().decode(BoardItem.self, from: data)
        }

        func encode() -> Data? {
            do {
                return try JSONEncoder().encode(self)
            } catch {
                print("Error encoding BoardItem")
                return nil
            }
        }
    }
}

//MARK: -Player

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
