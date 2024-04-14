//
//  TextInputItem.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 3/26/24.
//

import SwiftUI

struct TextInputItem: View {
    @FocusState private var isTextFieldFocused: Bool
    @State private var currentText: String
    let title: String
    let defaultText: String
    var text: Binding<String>
    
    init(title: String, defaultText: String, text: Binding<String>) {
        self.title = title
        self.defaultText = defaultText
        self.text = text
        self.currentText = text.wrappedValue
    }
    
    var body: some View {
        LabeledContent(title) {
            TextField(defaultText, text: $currentText)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.gray)
                .focused($isTextFieldFocused)
        }
        .onChange(of: isTextFieldFocused) { _ in textFieldDidChangeFocus()}
        .onChange(of: text.wrappedValue) { _ in textDidChangeValue()}
    }
    
    private func textFieldDidChangeFocus() {
        if isTextFieldFocused {
            currentText = ""
        } else {
            if currentText == "" {
                currentText = text.wrappedValue
            } else {
                text.wrappedValue = currentText
            }
        }
    }
    
    private func textDidChangeValue() {
        if !isTextFieldFocused {
            currentText = text.wrappedValue
        }
    }
}

struct TextInputItem_Previews: PreviewProvider {
    static var previews: some View {
        @State var text = ""

        TextInputItem(title: "Title", defaultText: "Default Text", text: $text)
    }
}
