//
//  MCConnector.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/2/23.
//

import Foundation
import MultipeerConnectivity

class MCConnector: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    typealias BoardItem = TicTacToeGame<Player>.BoardItem
    
    private let serviceType = "atk-ttt-srvc"
    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    private var availablePeer: [MCPeerID] = []
    private var pendingInvitation: [(peer:MCPeerID, invitationHandler:(Bool, MCSession?) -> Void)] = []
    var isConnected = false
    
    var delegate : MCConnectorDelegate?
    
    init(withPublicName publicName: String) {
        self.peerID = MCPeerID(displayName: publicName)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
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
    
    func send(key: ConnData.ConnDataKey, withData data: Data?) {
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
            if let delegate = delegate {
                DispatchQueue.main.async {
                    delegate.didRecieveInvitationFrom(MCCPeer(id: peerID.hash, name: peerID.displayName))
                }
            }
            
            pendingInvitation.append((peerID, invitationHandler))
        } else {
            invitationHandler(false, nil)
        }
    }
    
    //MARK: -MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        availablePeer.append(peerID)
        if let delegate = delegate {
            DispatchQueue.main.async {
                delegate.didFoundPeer(MCCPeer(id: peerID.hash, name: peerID.displayName))
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        availablePeer.removeAll{$0==peerID}
        if let delegate = delegate {
            DispatchQueue.main.async {
                delegate.didLostPeer(MCCPeer(id: peerID.hash, name: peerID.displayName))
            }
        }
    }
    
    //MARK: -MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if let delegate = delegate {
            DispatchQueue.main.async {
                switch state {
                case .notConnected:
                    self.session = nil
                    self.isConnected = false
                    delegate.didDisconnect()
                case .connected:
                    self.stopAdvertising()
                    delegate.didConnectTo(MCCPeer(id: peerID.hash, name: peerID.displayName))
                    self.isConnected = true
                default:
                    print("Session State:\(state) not handled")
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let delegate = delegate {
            DispatchQueue.main.async {
                do {
                    let connData = try ConnData(fromData: data)
                    
                    switch connData.key {
                    case .player:
                        delegate.didRecievePlayer(try Player(fromData: connData.data!))
                    case .move:
                        delegate.didRecieveMove(try BoardItem(fromData: connData.data!))
                    case .restart:
                        delegate.didReceiveStartANewGame()
                    case .message:
                        print("Message received: \(try String(fromData: connData.data!))")
                    }
                    
                } catch {
                    print("Error receiving message...")
                }
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
        var state: MSSPeerState = .idle
        
        enum MSSPeerState {
            case idle
            case waitingResponse
            case connecting
            case connected
        }
    }
}

//MARK: -MCConnectorDelegate

protocol MCConnectorDelegate {
    func didFoundPeer(_ peer: MCConnector.MCCPeer)
    
    func didLostPeer(_ peer: MCConnector.MCCPeer)
    
    func didRecieveInvitationFrom(_ peer: MCConnector.MCCPeer)
    
    func didConnectTo(_ peer: MCConnector.MCCPeer)
    
    func didDisconnect()
    
    func didRecievePlayer(_ player: Player)
    
    func didRecieveMove(_ boardItem: TicTacToeGame<Player>.BoardItem)
    
    func didReceiveStartANewGame()
}
