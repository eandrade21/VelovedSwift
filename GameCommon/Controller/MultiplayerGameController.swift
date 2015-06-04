//
//  MultiplayerGameController.swift
//  GameSwift
//
//  Created by eandrade21 on 5/25/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import MultipeerConnectivity

public class MultiplayerGameController: GameController{

    var messageQueue = [MPCMessage]()
    var ackCounter = 0
    var status: MultiplayerGameStatus!
    var playerMap = [MCPeerID : Player]()

    public override init() {
        super.init()
        status = MultiplayerGameIdleStatus(controller: self)
    }

    func processMessage(message: MPCMessage) {
        status.processMessage(message)
    }

    func queueMessage(message: MPCMessage) {
        messageQueue.append(message)
    }

    func dequeueMessage() -> MPCMessage? {
        if !messageQueue.isEmpty {
            return messageQueue.removeAtIndex(0)
        }
        return nil
    }

    public override func startGame() {
        let didShowGameViewControllerMsg = MPCMessage.getDidShowGameViewControllerMessage()
        MPCController.sharedMPCController.sendMessage(didShowGameViewControllerMsg)
    }

    public override func setUpModel() {

        initStage()

        initializeTarget()
        initializePlayer()
    }

    func initStage() {
        let stageConfigurator = StageConfiguratorLevel1(size: DefaultStageSize)
        stage = Stage.sharedStage
        stage.configurator = stageConfigurator
        stage.delegate = self
    }

    func initializeTarget() {
        let targetLocations = stage.randomLocations(DefaultTargetSize)
        let targetConfiguration = TargetConfiguration(locations: targetLocations, mode: .NoUpdate)

        let initTargetMessage = MPCMessage.getInitTargetMessage(targetConfiguration)
        MPCController.sharedMPCController.sendMessage(initTargetMessage)

        targetConfiguration.mode = .SelfUpdate

        initializeTargetWithConfiguration(targetConfiguration)
    }

    func initializeTargetWithConfiguration(targetConfiguration: TargetConfiguration) -> Target {
        let target = Target(locations: targetConfiguration.locations,
            value: DefaultTargetValue,
            mode: targetConfiguration.mode)
        stage.addElement(target)
        target.delegate = stage
        return target
    }

    func initializePlayer() {

        let playerDirection = Direction.randomDirection()
        let playerLocations = stage.randomLocations(DefaultPlayerSize, direction: playerDirection)
        let playerType = PlayerType(rawValue: UInt(MPCController.sharedMPCController.precedence))!

        let playerConfig = PlayerConfiguration(locations: playerLocations,
            direction: playerDirection,
            type: playerType)

        let initPlayerMsg = MPCMessage.getInitPlayerMessage(playerConfig)
        MPCController.sharedMPCController.sendMessage(initPlayerMsg)

        let player = initializePlayerWithConfiguration(playerConfig, peerID: MPCController.sharedMPCController.peerID)

        playerController = PlayerController(bindings: KeyboardControlBindings())
        playerController.isProcessingKeyInput = false
        playerController.registerPlayer(player)
    }

    func initializePlayerWithConfiguration(playerConfiguration: PlayerConfiguration, peerID: MCPeerID) -> Player {

        let player = Player(locations: playerConfiguration.locations,
            direction: playerConfiguration.direction)
        player.type = playerConfiguration.type
        player.delegate = stage
        stage.addElement(player)

        playerMap[peerID] = player

        return player
    }

    func isMyInitializationTurn() -> Bool {

        if let players = stage.elements[Player.elementName] {
            if players.count == MPCController.sharedMPCController.precedence {
                return true
            }
        } else if MPCController.sharedMPCController.isHighestPrecedence {
            return true
        }

        return false
    }

    func areAllPlayersInitialized() -> Bool {
        if let players = stage.elements[Player.elementName] {
            if players.count > MPCController.sharedMPCController.getConnectedPeers().count {
                return true
            }
        }
        return false
    }

    func isElementAPlayerLocallyInitialized(element: StageElement) -> Bool {
        if let player = playerMap[MPCController.sharedMPCController.peerID] {
            if player === element && element.isMemberOfClass(Player){
                return true
            }
        } else {
            println("ERROR: Player Map has a peerID key with no player value")
        }
        return false
    }

    public override func processKeyInput(key: String, transform: StageViewTransform) -> Direction? {
        if let direction = super.processKeyInput(key, transform: transform) {

            println("Status: \(status). Player Controller Status - Processing keys \(playerController.isProcessingKeyInput)")
            let elementVector = StageElementVector(locations: [], direction: direction)
            let playerDidChangeDirectionMessage = MPCMessage.getPlayerDidChangeDirectionMessage(elementVector)
            MPCController.sharedMPCController.sendMessage(playerDidChangeDirectionMessage)

            return direction
        }
        return nil
    }
}

extension MultiplayerGameController: StageDelegate {


    func broadcastElementDidMoveEvent(element: StageElement) {

        if isElementAPlayerLocallyInitialized(element) {
            if let player = element as? Player {
                let vector = player.getStageElementVector()
                let elementDidMoveMessage = MPCMessage.getElementDidMoveMessage(vector)
                MPCController.sharedMPCController.sendMessage(elementDidMoveMessage)
            }
        }

        if element.isMemberOfClass(Target) {
            let vector = element.getStageElementVector()
            let targetDidUpdateLocationMessage = MPCMessage.getTargetDidUpdateLocationMessage(vector)
            MPCController.sharedMPCController.sendMessage(targetDidUpdateLocationMessage)
        }
    }

    func elementLocationDidChange(element: StageElement, inStage stage: Stage) {
        viewController?.drawElement(element)
    }

    func validateGameLogicUsingElement(element: StageElement, inStage stage: Stage) {

         if stage.numberOfActivePlayers() == 1 {
            (element as Player).deactivate()
            status = MultiplayerGameDidEndStatus(controller: self)

            let gameDidEndMessage = MPCMessage.getGameDidEndMessage()
            MPCController.sharedMPCController.sendMessage(gameDidEndMessage)
            return
        }

        if isElementAPlayerLocallyInitialized(element) {
            if let player = element as? Player {
                if stage.didPlayerCrash(player) || stage.didPlayerEatItself(player) {

                    let playerDidCrashMessage = MPCMessage.getPlayerDidCrashMessage()
                    MPCController.sharedMPCController.sendMessage(playerDidCrashMessage)

                    playerDidCrash(playerDidCrashMessage)
                } else if let target = stage.didPlayerSecureTarget(player) {

                    target.wasSecured()
                    let newVector = StageElementVector(locations: target.locations, direction: nil)
                    let targetWasSecuredMessage = MPCMessage.getTargetWasSecuredMessage(newVector)
                    MPCController.sharedMPCController.sendMessage(targetWasSecuredMessage)


                    let playerDidSecureTargetMessage = MPCMessage.getPlayerDidSecureTargetMessage()
                    MPCController.sharedMPCController.sendMessage(playerDidSecureTargetMessage)
                    playerDidSecureTarget(playerDidSecureTargetMessage)

                }
            }
        }
    }
}

extension MultiplayerGameController: GameMessages {

    func testMessage(message: MPCMessage) {
        // Do nothing
    }

    func didShowGameViewController(message: MPCMessage) {

        ackCounter++
        if ackCounter == MPCController.sharedMPCController.getConnectedPeers().count {
            ackCounter = 0
            status = MultiplayerGameModelInitStatus(controller: self)
            if MPCController.sharedMPCController.isHighestPrecedence {
                setUpModel()
            }
        }
    }

    func initPlayer(message: MPCMessage) {

        if stage == nil {
            initStage()
        }

        if let body = message.body {
            if let playerConfig = body[MPCMessageKey.PlayerConfig.rawValue] as? PlayerConfiguration {
                initializePlayerWithConfiguration(playerConfig, peerID: message.sender)
            }
        }

        if areAllPlayersInitialized() {
            initView()
        } else if isMyInitializationTurn() {
            initializePlayer()
            if areAllPlayersInitialized() {
                initView()
            }
        }
    }

    func initView() {
        status = MultiplayerGameViewInitStatus(controller: self)
        dispatch_async(dispatch_get_main_queue()) {
            self.setUpView()
            self.status = MultiplayerGameWaitingToScheduleGameStatus(controller: self)
        }
        scheduleGame()
    }

    func scheduleGame() {

        if MPCController.sharedMPCController.isHighestPrecedence {

            let gameStartTime = NSDate(timeIntervalSinceNow: 3)
            let gameStartTimeString: String = String(format: "%f", gameStartTime.timeIntervalSince1970)

            let scheduleMsg = MPCMessage.getScheduleGameMessage(gameStartTimeString)
            MPCController.sharedMPCController.sendMessage(scheduleMsg)

            scheduleGameAtSpecificTime(gameStartTimeString)
        }
    }

    func scheduleGame(message: MPCMessage) {
        if let body = message.body {
            if let gameStartTime = body[MPCMessageKey.GameStartDate.rawValue] as? String {

                let didScheduleGameMsg = MPCMessage.getDidScheduleGameMessage()
                MPCController.sharedMPCController.sendMessage(didScheduleGameMsg)
                scheduleGameAtSpecificTime(gameStartTime)
            }
        }
    }

    func scheduleGameAtSpecificTime(gameStartTime: String) {

                let gameStartTimeInterval = (gameStartTime as NSString).doubleValue
                let futureDate = NSDate(timeIntervalSince1970: gameStartTimeInterval)
                var futureDateSpec = timespec(tv_sec: Int(futureDate.timeIntervalSince1970), tv_nsec: 0)
                dispatch_after(dispatch_walltime(&futureDateSpec, 0), dispatch_get_main_queue()) {
                    self.status = MultiplayerGamePlayingStatus(controller: self)
                    self.animateStage()
                }
    }

    func didScheduleGame(message: MPCMessage) {
        ackCounter++
        if ackCounter == MPCController.sharedMPCController.getConnectedPeers().count {
            ackCounter = 0
            println("All players scheduled the game")
        }
    }

    func elementDidMoveMessage(message: MPCMessage) {
        if let body = message.body {
            if let elementVector = body[MPCMessageKey.ElementVector.rawValue] as? StageElementVector {

                let sourcePlayer = playerMap[message.sender]
                sourcePlayer?.locations = elementVector.locations
                if let _ = elementVector.direction {
                    sourcePlayer?.direction = elementVector.direction!
                }
            }
        }
    }

    func playerDidCrash(message: MPCMessage) {

        if let player = playerMap[message.sender] {
            player.deactivate()
            elementLocationDidChange(player, inStage: stage)
        }
    }

    func playerDidChangeDirection(message: MPCMessage) {
        if let body = message.body {
            if let player = playerMap[message.sender] {
                let elementVector = body[MPCMessageKey.ElementVector.rawValue] as? StageElementVector
                player.direction = elementVector!.direction!
            }
        }
    }

    func playerDidSecureTarget(message: MPCMessage) {
        if let player = playerMap[message.sender] {
            player.didSecureTarget()
        }
    }

    func initTarget(message: MPCMessage) {

        if stage == nil {
            initStage()
        }

        if let body = message.body {
            if let targetConfig = body[MPCMessageKey.TargetConfig.rawValue] as? TargetConfiguration {
                initializeTargetWithConfiguration(targetConfig)
            }
        }
    }

    func targetWasSecured(message: MPCMessage) {
        if let targets = stage.elements[Target.elementName] {
            if let target = targets.first {
                if let body = message.body {
                    if let newVector = body[MPCMessageKey.ElementVector.rawValue] as? StageElementVector {
                        (target as Target).wasSecured(newVector.locations)
                    }
                }
            }
        }
    }
    func targetDidUpdateLocation(message: MPCMessage) {
        if let targets = stage.elements[Target.elementName] {
            if let target = targets.first {
                if let body = message.body {
                    if let newVector = body[MPCMessageKey.ElementVector.rawValue] as? StageElementVector {
                        (target as Target).updateLocation(newVector.locations)
                    }
                }
            }
        }
    }

    func gameDidEnd(message: MPCMessage) {
        ackCounter++
        if ackCounter == MPCController.sharedMPCController.getConnectedPeers().count {
            ackCounter = 0
            println("All players did end game")
        }
    }
}

extension MultiplayerGameController: MPCControllerDelegate {
    public func didUpdatePeers() {
        // Do nothing for now
    }

    public func didReceiveMessage(message: MPCMessage) {
        processMessage(message)
    }
}