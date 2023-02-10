//
//  MCConnector.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/2/23.
//

import Foundation
import MultipeerConnectivity

class MCConnector: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    typealias BoardPosition = GameViewModel.BoardPosition
    
    private let serviceType = "atk-ttt-srvc"
    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    private var availablePeer: [MCPeerID] = []
    private var pendingInvitation: [(peer:MCPeerID, invitationHandler:(Bool, MCSession?) -> Void)] = []
    private var delegate : MCConnectorDelegate
    
    var isConnected = false
    
    init(withPublicName publicName: String, andDelegate delegate: MCConnectorDelegate) {
        self.peerID = MCPeerID(displayName: publicName)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        self.delegate = delegate
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
        
    }
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        availablePeer.removeAll()
    }
    
    func invitePeer(_ peer: MCCPeer) {
        session = MCSession.init(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        if let invtPeer = availablePeer.first(where:{$0.hash==peer.id}) {
            browser.invitePeer(invtPeer, to: session!, withContext: nil, timeout: 60)
        }
    }
    
    func respondInvitationFor(_ peer:MCCPeer, withValue value: Bool) {
        session = MCSession.init(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        if let index = pendingInvitation.firstIndex(where:{$0.peer.hash==peer.id}) {
            let invitation = pendingInvitation.remove(at:index)
            
            invitation.invitationHandler(value, session)
        }
    }
    
    func send(_ key: ConnData.ConnDataKey, withData data: Data?) {
        if let session = session {
            if !session.connectedPeers.isEmpty {
                do {
                    try session.send(ConnData(key:key, data: data).encode(), toPeers: session.connectedPeers, with: .reliable)
                } catch {
                    print("Error sending message...")
                }
            }
        }
    }
    
    //MARK: -MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if session == nil {
            DispatchQueue.main.async {
                self.delegate.didRecieveInvitationFrom(MCCPeer(id: peerID.hash, name: peerID.displayName))
            }
            pendingInvitation.append((peerID, invitationHandler))
        } else {
            invitationHandler(false, nil)
        }
    }
    
    //MARK: -MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        availablePeer.append(peerID)
        DispatchQueue.main.async {
            self.delegate.didFoundPeer(MCCPeer(id: peerID.hash, name: peerID.displayName))
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        availablePeer.removeAll{$0==peerID}
        DispatchQueue.main.async {
            self.delegate.didLostPeer(MCCPeer(id: peerID.hash, name: peerID.displayName))
        }
    }
    
    //MARK: -MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.session = nil
                self.isConnected = false
                self.delegate.didDisconnect()
            case .connected:
                self.stopAdvertising()
                self.delegate.didConnectTo(MCCPeer(id: peerID.hash, name: peerID.displayName))
                self.isConnected = true
            case .connecting:
                print("TODO: Handle connecting state")
            default:
                print("Session State:\(state) not handled")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            do {
                let connData = try ConnData(fromData: data)
                
                switch connData.key {
                case .player:
                    self.delegate.didRecievePlayer(try Player(fromData: connData.data!))
                case .move:
                    self.delegate.didRecieveMove(try BoardPosition(fromData: connData.data!))
                case .restart:
                    self.delegate.didReceiveRestart()
                case .message:
                    print("Message received: \(try String(fromData: connData.data!))")
                }
            } catch {
                print("Error receiving message...")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Session didReceive stream not handled")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Session didStartReceivingResourceWithName stream not handled")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Session didFinishReceivingResourceWithName not handled")
    }
    
    //MARK: -CommData
    
    struct ConnData:Codable {
        var key: ConnDataKey
        var data: Data?
        
        init(key: ConnDataKey, data: Data?) {
            self.key = key
            self.data = data
        }
        
        init(fromData data: Data) throws {
            self = try JSONDecoder().decode(ConnData.self, from: data)
        }
        
        func encode() throws -> Data {
            return try JSONEncoder().encode(self)
        }
        
        enum ConnDataKey:Codable {
            case player
            case move
            case restart
            case message
        }
    }
    
    //MARK: -MCCPeer
    
    struct MCCPeer: Equatable, Identifiable {
        let id : Int
        let name : String
        var state: MCCPeerState = .idle
        
        enum MCCPeerState {
            case idle
            case waitingResponse
            case connecting
            case connected
        }
        
        static func == (lhs: MCCPeer, rhs: MCCPeer) -> Bool {
            return lhs.id == rhs.id
        }
    }
}

//MARK: -MCConnectorDelegate

protocol MCConnectorDelegate {
    typealias BoardPosition = MCConnector.BoardPosition
    
    func didFoundPeer(_ peer: MCConnector.MCCPeer)
    
    func didLostPeer(_ peer: MCConnector.MCCPeer)
    
    func didRecieveInvitationFrom(_ peer: MCConnector.MCCPeer)
    
    func didConnectTo(_ peer: MCConnector.MCCPeer)
    
    func didDisconnect()
    
    func didRecievePlayer(_ player: Player)
    
    func didRecieveMove(_ position: BoardPosition)
    
    func didReceiveRestart()
}
