//
//  AlertHandler.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 3/14/24.
//

import Foundation
import SwiftUI

class AlertHandler: ObservableObject {
    private var alerts = [Alert]()
    private var responders = [AlertHandlerResponder]()
    private var firstResponder: AlertHandlerResponder? {responders.first}
    
    func showAlert(_ alert: Alert, after time: TimeInterval = 0) {
        alerts.append(alert)
        showFirstAlert(after: time)
    }
    
    fileprivate func isShowingAlertDidChange() {
        guard let firstResponder = firstResponder else {return}
        
        if firstResponder.isShowingAlert {
            if alerts.isEmpty {
                firstResponder.isShowingAlert = false
            }
        } else {
            if alerts.count >= 1 {
                alerts.removeFirst()
                
                if !alerts.isEmpty {
                    showFirstAlert(after: 0.3)
                }
            }
        }
    }
    
    fileprivate func alertToShow() -> Alert {
        if let alert = alerts.first {
            alert
        } else {
            fatalError("AlertHandler - No alert to be shown")
        }
    }
    
    fileprivate func addResponder(_ responder: AlertHandlerResponder) {
        removeResponder(id: responder.id)
        responders.insert(responder, at: 0)
        responder.isShowingAlert = !alerts.isEmpty
    }
    
    fileprivate func removeResponder(id: UUID) {
        responders.removeAll(where: {$0.id == id})
    }
    
    private func showFirstAlert(after time: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            self.firstResponder?.isShowingAlert = true
        }
    }
}

fileprivate class AlertHandlerResponder {
    let id: UUID
    private var _isShowingAlert: Binding<Bool>
    var isShowingAlert: Bool {
        get {_isShowingAlert.wrappedValue}
        set(newValue) {_isShowingAlert.wrappedValue = newValue}
    }
    
    init(id: UUID, isShowingAlert: Binding<Bool>) {
        self.id = id
        self._isShowingAlert = isShowingAlert
    }
}

struct Alertable: ViewModifier {
    @EnvironmentObject private var alertHandler: AlertHandler
    @State private var responder: AlertHandlerResponder?
    @State private var isShowingAlert = false
    
    @State var count = 0
    
    func body(content: Content) -> some View {
        content
            .onAppear {didAppear()}
            .onDisappear {didDisappear()}
            .alert(isPresented: $isShowingAlert) {alertHandler.alertToShow()}
            .onChange(of: isShowingAlert) {_ in alertHandler.isShowingAlertDidChange()}
    }
    
    private func didAppear() {
        responder = AlertHandlerResponder(id: UUID(), isShowingAlert: $isShowingAlert)
        alertHandler.addResponder(responder!)
    }
    
    private func didDisappear() {
        if let responder = responder {
            alertHandler.removeResponder(id: responder.id)
        }
    }
}

extension View {
    func alertable() -> some View {
        modifier(Alertable())
    }
}
