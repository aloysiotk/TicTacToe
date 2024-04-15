//
//  GameBoardGrid.swift
//
//  Created by Aloysio Nandi Tiscoski on 27/01/22.
//

import SwiftUI

struct GameBoardGrid<Item, ItemView>: View where ItemView: View, Item: Identifiable {
    let columns: Int
    var items: [Item]
    var content: (Item) -> ItemView
    
    private let gridItems: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: gridItems) {
            ForEach(items) { item in
                content(item)
                    .aspectRatio(1, contentMode: .fill)
            }
        }
        .background {
            Image("Board")
                .resizable()
        }
    }
    
    init(columns: Int, items: [Item], content: @escaping (Item) -> ItemView) {
        self.columns = columns
        self.items = items
        self.content = content
        self.gridItems = Array(repeating: GridItem(.flexible()), count: columns)
    }
}

struct GameBoardGrid_Previews: PreviewProvider {
    struct PreviewElement: Identifiable {
        var value: Int
        var id: Int { value }
    }
    
    static var previews: some View {
        let itens = (0..<9).map{PreviewElement(value: $0)}
        
        GameBoardGrid(columns: 3, items: itens) { item in
            Rectangle()
                .foregroundStyle(.blue.opacity(0.7))
                .overlay(Text(item.value.description))
        }
        .padding(.horizontal)
    }
}



