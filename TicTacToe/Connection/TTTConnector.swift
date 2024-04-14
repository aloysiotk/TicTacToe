//
//  TTTConnector.swift
//  TicTacToe
//
//  Created by Aloysio Tiscoski on 2/2/23.
//

import Foundation
import MultipeerConnectivity

class TTTConnector: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    private let serviceType = "atk-ttt-srvc"
    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    private var availablePeers: [MCPeerID] = []
    private var pendingInvitations: [Invitation] = []
    private var delegate : MCConnectorDelegate
    private var connectedPeer: MCPeerID?
    
    var isConnected: Bool {(session?.connectedPeers.count ?? 0 > 0)}
    
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
        availablePeers.removeAll()
    }
    
    func invitePeer(_ peer: TTTPeer) {
        guard let invitePeer = availablePeers.first(where:{$0.hash==peer.id}) else {return}
        
        let session = MCSession.init(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session
        
        browser.invitePeer(invitePeer, to: session, withContext: nil, timeout: 30)
    }
    
    func respondInvitationFor(_ peer:TTTPeer, withValue value: Bool) {
        guard let pendingInvitation = pendingInvitations.removePeer(peer) else {return}
        
        if value {
            session = MCSession.init(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
            session?.delegate = self
        }
        
        pendingInvitation.invitationHandler(value, value ? session : nil)
    }
    
    func disconnect() {
        session?.delegate = nil
        session?.disconnect()
        session = nil
        
        if let peer = connectedPeer {
            delegate.didDisconnectFrom(TTTPeer(id: peer.hash, name: peer.displayName), showAlert: false)
        }
        
        connectedPeer = nil
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
        if isConnected {
            invitationHandler(false, nil)
        } else {
            DispatchQueue.main.async {
                self.delegate.didReceiveInvitationFrom(TTTPeer(id: peerID.hash, name: peerID.displayName))
            }
            pendingInvitations.append(Invitation(peer: peerID, invitationHandler: invitationHandler))
        }
    }
    
    //MARK: -MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        availablePeers.append(peerID)
        DispatchQueue.main.async {
            self.delegate.didFoundPeer(TTTPeer(id: peerID.hash, name: peerID.displayName))
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        availablePeers.removeAll{$0==peerID}
        DispatchQueue.main.async {
            self.delegate.didLostPeer(TTTPeer(id: peerID.hash, name: peerID.displayName))
        }
    }
    
    //MARK: -MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            let peer =  TTTPeer(id: peerID.hash, name: peerID.displayName)
            
            switch state {
            case .notConnected:
                self.session = nil
                if self.connectedPeer != nil {
                    self.delegate.didDisconnectFrom(peer, showAlert: true)
                    self.connectedPeer = nil
                } else {
                    self.delegate.didReceiveDeclineFrom(peer)
                }
            case .connected:
                self.stopAdvertising()
                self.connectedPeer = peerID
                self.delegate.didConnectTo(peer)
            case .connecting:
                print("Connecting state")
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
                    self.delegate.didReceivePlayer(try Player(fromData: connData.data!))
                case .move:
                    self.delegate.didReceiveMove(try BoardPosition(fromData: connData.data!))
                case .restart:
                    self.delegate.didReceiveRestart()
                case .message:
                    let peer =  TTTPeer(id: peerID.hash, name: peerID.displayName)
                    self.delegate.didReceiveMessage(try String(fromData: connData.data!),  from: peer)
                }
            } catch {
                print("Error reading data...")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Session didReceive stream not handled")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Session didStartReceivingResourceWithName not handled")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Session didFinishReceivingResourceWithName not handled")
    }
    
    struct Invitation {
        var peer: MCPeerID
        var invitationHandler: (Bool, MCSession?) -> Void
    }
    
}

//MARK: -MCConnectorDelegate

protocol MCConnectorDelegate {
    func didFoundPeer(_ peer: TTTPeer)
    
    func didLostPeer(_ peer: TTTPeer)
    
    func didReceiveInvitationFrom(_ peer: TTTPeer)
    
    func didReceiveDeclineFrom(_ peer: TTTPeer)
    
    func didConnectTo(_ peer: TTTPeer)
    
    func didDisconnectFrom(_ peer: TTTPeer, showAlert: Bool)
    
    func didReceivePlayer(_ player: Player)
    
    func didReceiveMove(_ position: BoardPosition)
    
    func didReceiveRestart()
    
    func didReceiveMessage(_ message: String, from peer: TTTPeer)
}
