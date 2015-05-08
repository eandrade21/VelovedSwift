//
//  iOS_GameLobbyViewController.swift
//  SnakeSwift
//
//  Created by eandrade21 on 4/20/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import UIKit
import SnakeCommon

enum GameInvitationStatus {
    case Pending
    case Accepted
}

class iOS_GameLobbyViewController: UIViewController {


    let mainButtonTitleBrowsing = "Join Game"
    let mainButtonTitleAdvertising = "Start Game"

    var mode: MPCControllerMode
    var browsingPeersController: iOS_MPCFoundPeersController?

    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet var peerInviteViews: [iOS_PeerInvite]!

    init(mode: MPCControllerMode) {
        self.mode = mode

        super.init(nibName: "iOS_GameLobbyViewController", bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(animated: Bool) {


        switch mode {
        case .Advertising:
            configureMainButton()
            
            registerMPCPeerInvitesDidChangeNotification()

            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "showSnakeGameViewController",
                name: MPCDidReceiveMessageNotification,
                object: MPCController.sharedMPCController)

            MPCController.sharedMPCController.setMode(mode)
            MPCController.sharedMPCController.startAdvertising()

        case .Browsing:
            if mode == MPCControllerMode.Browsing {
                configureMainButton()
                presentBrowsingPeersController()
            }

            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "showSnakeGameViewController",
                name: MPCDidReceiveMessageNotification,
                object: MPCController.sharedMPCController)

            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "updatePeerInviteViews",
                name: MPCPeerInvitesDidChangeNotification,
                object: MPCController.sharedMPCController)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        unregisterMPCPeerInvitesDidChangeNotification()
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: MPCDidReceiveMessageNotification,
            object: MPCController.sharedMPCController)
    }

    func configureMainButton() {
        switch mode {
        case .Browsing:
            mainButton.setTitle(mainButtonTitleBrowsing, forState: .Normal)
            mainButton.setTitle(mainButtonTitleBrowsing, forState: .Highlighted)
            mainButton.setTitle(mainButtonTitleBrowsing, forState: .Selected)
        case .Advertising:
            mainButton.setTitle(mainButtonTitleAdvertising, forState: .Normal)
            mainButton.setTitle(mainButtonTitleAdvertising, forState: .Highlighted)
            mainButton.setTitle(mainButtonTitleAdvertising, forState: .Selected)
        }
    }

    func presentBrowsingPeersController() {
        browsingPeersController = iOS_MPCFoundPeersController()

        presentViewController(browsingPeersController!.alertController, animated: true, completion: {
            MPCController.sharedMPCController.setMode(self.mode)
            MPCController.sharedMPCController.startBrowsing()
        })
    }

    func updatePeerInviteViews() {
        dispatch_async(dispatch_get_main_queue()) {
            let peerInvites = MPCController.sharedMPCController.getPeerInvites()
            for (index, invite) in enumerate(peerInvites) {
                let peerInviteView = self.peerInviteViews[index] as iOS_PeerInvite
                peerInviteView.peerNameLabel.text = invite.peerID.displayName
                peerInviteView.statusLabel.text = invite.status.description
            }
        }
    }
    
    func registerMPCPeerInvitesDidChangeNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updatePeerInviteViews",
            name: MPCPeerInvitesDidChangeNotification,
            object: MPCController.sharedMPCController)
    }

    func unregisterMPCPeerInvitesDidChangeNotification() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: MPCPeerInvitesDidChangeNotification,
            object: MPCController.sharedMPCController)
    }
}

extension iOS_GameLobbyViewController {


    @IBAction func mainButtonAction(sender: UIButton) {
        switch mode {
        case .Browsing:
            presentBrowsingPeersController()
        case .Advertising:
            
            let setUpGameMsg = MPCMessage.getSetUpGameMessage()
            MPCController.sharedMPCController.sendMessage(setUpGameMsg)

            showSnakeGameViewController()
        }
    }

    func showSnakeGameViewController() {

        var gameMode: SnakeGameMode

        switch mode {
        case .Advertising:
            gameMode = SnakeGameMode.MultiPlayerMaster
        case .Browsing:
            gameMode = SnakeGameMode.MultiplayerSlave
        }

        dispatch_async(dispatch_get_main_queue()) {
            let snakeGameVC = iOS_SnakeGameViewController(gameMode: gameMode)
            self.showViewController(snakeGameVC, sender: self)
        }
    }

}