//
//  GameBoardGrid.swift
//  Memorize
//
//  Created by Aloysio Nandi Tiscoski on 27/01/22.
//

import SwiftUI

struct GameBoardGrid<Item, ItemView>: View where ItemView: View, Item: Identifiable {
    let columns: Int
    var itens: [Item]
    var content: (Item) -> ItemView
    
    var body: some View {
        GeometryReader { geometry in
            let minDimension = CGFloat(min(geometry.size.width, geometry.size.height))
            let columnWidth = (minDimension * CGFloat(columns-1)) / CGFloat(columns)
            let gridItens = Array(repeating:GridItem(.adaptive(minimum: columnWidth)), count: columns)
            
            ZStack{
                LazyVGrid(columns: gridItens) {
                    ForEach(itens) { item in
                        content(item)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
                .background(Image("Board").resizable())
            }
        }
    }
}


