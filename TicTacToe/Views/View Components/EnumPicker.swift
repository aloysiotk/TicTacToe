//
//  EnumPicker.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 3/8/24.
//

import SwiftUI

struct EnumPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.AllCases : RandomAccessCollection, T.RawValue : StringProtocol {
    var label: String
    var selection: Binding<T>
    
    var body: some View {
        Picker(label, selection: selection) {
            ForEach(T.allCases, id: \.self) { option in
                Text(option.rawValue.capitalized).tag(option)
            }
        }
        .listRowSeparator(.visible)
    }
}
