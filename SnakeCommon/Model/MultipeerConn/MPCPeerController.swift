//
//  MPCPeerController.swift
//  SnakeSwift
//
//  Created by eandrade21 on 5/18/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MPCPeerControllerActions {
    func peerWasFound(aPeer: MCPeerID)
    func peerWasLost(aPeer: MCPeerID)
    func peerWasInvited(aPeer: MCPeerID)
    func peerDidReceiveInvitation(aPeer: MCPeerID)
    func peerIsConnecting(aPeer: MCPeerID)
    func peerDidConnect(aPeer: MCPeerID)
    func peerDidNotConnect(aPeer: MCPeerID)
}

protocol MPCPeerControllerDelegate: class {
    func didUpdatePeers()
}

class MPCPeerController: NSObject, MPCPeerControllerActions {

    private let kPeerIDKey = "peerIDKey"
    private let kDefaultHostName = "UnknowHostName"

    var peerID: MCPeerID
    var peers = [MCPeerID : MPCPeerIDStatus]()
    weak private var delegate: MPCPeerControllerDelegate?
    private var mode: MPCPeerControllerMode?

    init(delegate: MPCPeerControllerDelegate) {

        #if os(iOS)
            if let peerIDData = NSUserDefaults.standardUserDefaults().dataForKey(kPeerIDKey) {
                self.peerID = NSKeyedUnarchiver.unarchiveObjectWithData(peerIDData) as MCPeerID
            } else {
                self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
                let peerIDData = NSKeyedArchiver.archivedDataWithRootObject(self.peerID)
                NSUserDefaults.standardUserDefaults().setObject(peerIDData, forKey: kPeerIDKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        #elseif os(OSX)
            var displayName: String

            let pid = NSProcessInfo.processInfo().processIdentifier
            if let hostname = NSHost.currentHost().name {
                displayName = String(format: "%@-%d", arguments: [hostname, pid])
            } else {
                displayName = String(format: "%@-%d", arguments: [kDefaultHostName, pid])
            }

            self.peerID = MCPeerID(displayName: displayName)
        #endif
        
        self.delegate = delegate
        super.init()

        self.mode = MPCPeerControllerIdleMode(peerController: self)
        self.updateStatus(.Initialized, forPeer: self.peerID)
    }

    func updateStatus(status: MPCPeerIDStatus, forPeer peer: MCPeerID) {
        peers[peer] = status
        delegate?.didUpdatePeers()
    }

    func removeStatusForPeer(peer: MCPeerID) {
        peers.removeValueForKey(peer)
        delegate?.didUpdatePeers()
    }

    func removeAllNonConnectedPeers() {
        for (peer, value) in peers {
            if value != .Connected {
                removeStatusForPeer(peer)
            }
        }

        if peers.isEmpty {
            peers[peerID] = .Initialized
        }

        delegate?.didUpdatePeers()
    }

    func resetMode() {
        mode = nil
        mode = MPCPeerControllerIdleMode(peerController: self)
    }

    func setBrowsingMode() {
        mode = nil
        mode = MPCPeerControllerBrowsingMode(peerController: self)
    }

    func setAdvertisingMode() {
        mode = nil
        mode = MPCPeerControllerAdvertisingMode(peerController: self)
    }

    func peerWasFound(aPeer: MCPeerID) {
        mode?.peerWasFound(aPeer)
    }

    func peerWasLost(aPeer: MCPeerID) {
        mode?.peerWasLost(aPeer)
    }

    func peerWasInvited(aPeer: MCPeerID) {
        mode?.peerWasInvited(aPeer)
    }

    func peerDidReceiveInvitation(aPeer: MCPeerID) {
        mode?.peerDidReceiveInvitation(aPeer)
    }

    func peerIsConnecting(aPeer: MCPeerID) {
        mode?.peerIsConnecting(aPeer)
    }

    func peerDidConnect(aPeer: MCPeerID) {
        mode?.peerDidConnect(aPeer)
    }

    func peerDidNotConnect(aPeer: MCPeerID) {
        mode?.peerDidNotConnect(aPeer)
    }
}

class MPCPeerControllerMode: NSObject, MPCPeerControllerActions {

    var peerController: MPCPeerController

    init(peerController: MPCPeerController) {
        self.peerController = peerController
        super.init()
    }

    deinit {
        peerController.removeAllNonConnectedPeers()
    }

    func peerWasFound(aPeer: MCPeerID) {
        assertionFailure("This is an abstract method that must be overriden by a subclass")
    }

    func peerWasLost(aPeer: MCPeerID) {
        assertionFailure("This is an abstract method that must be overriden by a subclass")
    }

    func peerWasInvited(aPeer: MCPeerID) {
        assertionFailure("This is an abstract method that must be overriden by a subclass")
    }

    func peerDidReceiveInvitation(aPeer: MCPeerID) {
        assertionFailure("This is an abstract method that must be overriden by a subclass")
    }

    func peerIsConnecting(aPeer: MCPeerID) {
        assertionFailure("This is an abstract method that must be overriden by a subclass")
    }

    func peerDidConnect(aPeer: MCPeerID) {
        if let peerStatus = peerController.peers[aPeer] {
            assert(peerStatus == MPCPeerIDStatus.Connecting, "Current state \(peerStatus) is invalid to transition to Connected")
            peerController.updateStatus(.Connected, forPeer: aPeer)
            peerController.updateStatus(.Connected, forPeer: peerController.peerID)
        } else {
            peerController.updateStatus(.Connected, forPeer: aPeer)
            peerController.updateStatus(.Connected, forPeer: peerController.peerID)
        }
    }

    func peerDidNotConnect(aPeer: MCPeerID) {
        if let peerStatus = peerController.peers[aPeer] {
            peerController.removeStatusForPeer(aPeer)
        } else {
            assertionFailure("Trying to remove a nonexisten peer")
        }
    }

}

class MPCPeerControllerBrowsingMode: MPCPeerControllerMode {

    override init(peerController: MPCPeerController) {
        super.init(peerController: peerController)

        if peerController.peers.count == 1 && peerController.peers[peerController.peerID] == .Initialized {
            peerController.updateStatus(.Browsing, forPeer: peerController.peerID)
        }

    }

    override func peerWasFound(aPeer: MCPeerID) {
        if peerController.peers[aPeer] == nil {
            println("MPCController \(peerController.peerID.displayName) found peer \(aPeer.displayName)")
            peerController.updateStatus(.Found, forPeer: aPeer)
        }
    }

    override func peerWasLost(aPeer: MCPeerID) {
        if let status = peerController.peers[aPeer] {
            if status == .Found {
                println("MPCController \(peerController.peerID.displayName) lost peer \(aPeer.displayName)")
                peerController.removeStatusForPeer(aPeer)
            }
        } else {
            assertionFailure("Trying to remove a nonexistent peer")
        }
    }

    override func peerWasInvited(aPeer: MCPeerID) {
        if let peerStatus = peerController.peers[aPeer] {
            assert(peerStatus == MPCPeerIDStatus.Found, "To invite a peer it must be on Found status")
            peerController.updateStatus(.Accepting, forPeer: aPeer)
            peerController.updateStatus(.Joining, forPeer: peerController.peerID)
        } else {
            assertionFailure("Inviting nonexisting peer")
        }
    }

    override func peerDidReceiveInvitation(aPeer: MCPeerID) {
        // This method does nothing on browsing mode
    }

    override func peerIsConnecting(aPeer: MCPeerID) {
        if let peerStatus = peerController.peers[aPeer] {
            assert(peerStatus == MPCPeerIDStatus.Accepting, "Current state \(peerStatus) is an invalid to transition to Connecting")
            peerController.updateStatus(.Connecting, forPeer: aPeer)
            peerController.updateStatus(.Connecting, forPeer: peerController.peerID)
        } else {
            assertionFailure("Connecting a nonexisting peer")
        }
    }

    override func peerDidNotConnect(aPeer: MCPeerID) {
        super.peerDidNotConnect(aPeer)

        if peerController.peers.count == 1 {
            peerController.updateStatus(.Browsing, forPeer: peerController.peerID)
        }
    }

}

class MPCPeerControllerAdvertisingMode: MPCPeerControllerMode {

    override init(peerController: MPCPeerController) {
        super.init(peerController: peerController)

        if peerController.peers.count == 1 && peerController.peers[peerController.peerID] == .Initialized {
            peerController.updateStatus(.Hosting, forPeer: peerController.peerID)
        }
    }

    override func peerWasFound(aPeer: MCPeerID) {
        // This method does nothing on advertising mode
    }

    override func peerWasLost(aPeer: MCPeerID) {
        // This method does nothing on advertising mode
    }

    override func peerWasInvited(aPeer: MCPeerID) {
        // This method does nothing on advertising mode
    }

    override func peerDidReceiveInvitation(aPeer: MCPeerID) {
        if let _ = peerController.peers[aPeer] {
            assertionFailure("Invitation received for an already existing peer")
        } else {
            peerController.updateStatus(.Joining, forPeer: aPeer)
            peerController.updateStatus(.Accepting, forPeer: peerController.peerID)
        }
    }

    override func peerIsConnecting(aPeer: MCPeerID) {
        if let peerStatus = peerController.peers[aPeer] {
            assert(peerStatus == MPCPeerIDStatus.Joining, "Current state \(peerStatus) is an invalid transition to Connecting")
            peerController.updateStatus(.Connecting, forPeer: aPeer)
            peerController.updateStatus(.Connecting, forPeer: peerController.peerID)
        } else {
            assertionFailure("Connecting to a nonexisting peer")
        }
    }

    override func peerDidNotConnect(aPeer: MCPeerID) {
        super.peerDidNotConnect(aPeer)

        if peerController.peers.count == 1 {
            peerController.updateStatus(.Hosting, forPeer: peerController.peerID)
        }
    }
}

class MPCPeerControllerIdleMode: MPCPeerControllerMode {

    override func peerWasFound(aPeer: MCPeerID) {
        // This method does nothing
    }

    override func peerWasLost(aPeer: MCPeerID) {
        // This method does nothing
    }

    override func peerWasInvited(aPeer: MCPeerID) {
        // This method does nothing
    }

    override func peerDidReceiveInvitation(aPeer: MCPeerID) {
        // This method does nothing
    }

    override func peerIsConnecting(aPeer: MCPeerID) {
        // This method does nothing
    }

    override func peerDidNotConnect(aPeer: MCPeerID) {
        super.peerDidNotConnect(aPeer)

        if peerController.peers.count == 1 {
            peerController.updateStatus(.Initialized, forPeer: peerController.peerID)
        }
    }
}