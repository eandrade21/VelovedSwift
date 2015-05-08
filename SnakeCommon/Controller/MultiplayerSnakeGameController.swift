//
//  File.swift
//  SnakeSwift
//
//  Created by eandrade21 on 4/23/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

public class MultiplayerSnakeGameController: SnakeGameController {

    override public func startGame() {
        setUpModel()
        setUpView()
        scheduleGame()
    }

    override public func setUpModel() {
        let stageConfigurator = StageConfiguratorLevel1(size: DefaultStageSize)
        stage = Stage.sharedStage
        stage.configurator = stageConfigurator
        stage.delegate = self

        let typeGenerator = SnakeTypeGenerator()
        var snakeConfigurator = SnakeConfigurator(stage: stage, bodySize: DefaultSnakeSize, typeGenerator: typeGenerator)
        let keyBindings = KeyboardControlBindings()
        snakeController = SnakeController(bindings: keyBindings)

        if let snake = snakeConfigurator.getSnake() {
            if snakeController.registerSnake(snake) {
                snake.delegate = stage
                stage.addElement(snake)
            }else {
                assertionFailure("Unable to register snake")
            }
        }
    }

    func scheduleGame() {
        
    }
}

extension MultiplayerSnakeGameController: StageDelegate {
    func elementLocationDidChange(element: StageElement, inStage stage: Stage) {
        viewController.drawElement(element)
    }

    func validateGameLogicUsingElement(element: StageElement, inStage stage: Stage) {
        let elementType = element.dynamicType.getClassName()
        if elementType == Snake.getClassName() {
            var snake = element as Snake
            if stage.didSnakeCrash(snake) ||  stage.didSnakeEatItself(snake) {
                snake.kill()
                self.elementLocationDidChange(element, inStage: stage)

                if stage.snakesAlive() <= 1 {
                    restartGame()
                }
            }else {
                if let apple = stage.didSnakeEatAnApple(snake) {
                    apple.wasEaten()
                    snake.didEatApple()
                }
            }
        }
    }
}