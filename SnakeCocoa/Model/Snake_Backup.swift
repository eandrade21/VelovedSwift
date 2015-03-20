//
//  Snake.swift
//  SnakeSwift
//
//  Created by eandrade21 on 3/2/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import Foundation


class Snake_Backup : NSObject {
    
    // MARK: Properties
    
    var snakeBody = [SnakeBodyPart]()
    var xLowerBound: Float
    var yLowerBound: Float
    var xUpperBound: Float
    var yUpperBound: Float
    var bodySize = 5
    
    var snakeHead : SnakeBodyPart {
        get {
            return snakeBody[0]
        }
        set(newHead) {
            snakeBody.removeAtIndex(0)
            snakeBody.insert(newHead, atIndex: 0)
        }
    }
    var tailBodyPart: SnakeBodyPart!
    
    var moveTimer : NSTimer!
    var defaultmoveTimerInterval: NSTimeInterval = 0.5
    var moveTimerInterval: NSTimeInterval = 0.5 {
        didSet {
            if moveTimerInterval <= 0 {
                moveTimerInterval = oldValue
            }
        }
    }
    var moveTimerDelta = 0.05
    
    var delegate: SnakeDelegate?
    
    // MARK: Initializers
    
    init(xLowerBound: Float, xUpperBound: Float, yLowerBound: Float, yUpperBound: Float) {
        
        // Bounds limits are used to determine the range of potential locations of a snake body part
        // Since the snake body part location is based on its center, the limits need to be adjusted by 0.5
        // Each potential locaiton is measured by increments of 1.0
        self.xLowerBound = xLowerBound + 0.5
        self.xUpperBound = xUpperBound - 0.5
        self.yLowerBound = yLowerBound + 0.5
        self.yUpperBound = yUpperBound - 0.5
        
        super.init()
        
        // Get random head origin and build body
        buildBody(randomHeadOrigin())
        
        // Schedule moveTimer
        scheduleMoveTimer()
    }
    
    deinit {
        moveTimer.invalidate()
    }
    
    // MARK: Class Methods
    
    func buildBody(head: SnakeBodyPart) {
        
        
        // Add head to the body
        snakeBody.append(head)
        
        var lastBodyPart = snakeBody.last
        for index in 1 ... bodySize {
            
            var newLocationX = lastBodyPart!.locationX
            var newLocationY = lastBodyPart!.locationY
            
            switch head.direction {
            case .Up:
                newLocationY += 1
            case .Down:
                newLocationY -= 1
            case .Left:
                newLocationX += 1
            case .Right:
                newLocationX -= 1
            }
            
            let newBodyPart = SnakeBodyPart(x: newLocationX, y: newLocationY, direction: head.direction)
            
            snakeBody.append(newBodyPart)
            lastBodyPart = newBodyPart
        }
    }
    
    func randomHeadOrigin() -> SnakeBodyPart {
        
        // Create an inset rectangle of the snake size so it isn't too close to the border
        let xLowerBoundInset = xLowerBound + Float(bodySize)
        let xUpperBoundInset = xUpperBound - Float(bodySize)
        let yLowerBoundInset = yLowerBound + Float(bodySize)
        let yUpperBoundInset = yUpperBound - Float(bodySize)
        
        let rangeX = UInt32(xUpperBoundInset) - UInt32(xLowerBoundInset)
        let locationX = xLowerBoundInset + Float(arc4random_uniform(rangeX))
        
        let rangeY = UInt32(yUpperBoundInset) - UInt32(yLowerBoundInset)
        let locationY = yLowerBoundInset + Float(arc4random_uniform(rangeY))
        
        return SnakeBodyPart(x: locationX, y: locationY, direction: Direction.randomDirection(), type: SnakeBodyPart.SnakeBodyPartType.Head)
    }
    
    func scheduleMoveTimer() {
        moveTimer = NSTimer(timeInterval: defaultmoveTimerInterval,
            target: self,
            selector: "move",
            userInfo: nil,
            repeats: true)
        NSRunLoop.currentRunLoop().addTimer(moveTimer, forMode: NSDefaultRunLoopMode)
        moveTimer.fire()
    }
    
    // MARK: Instance Methods
    func move() {
        
        precondition(snakeBody.count >= 2, "Snake should be at least 2 units long")
        
        // Save the tail body part
        if let lastPoint = snakeBody.last {
            tailBodyPart = lastPoint
        }
        
        // Rest head's type to body part
        var tempHead = snakeHead
        tempHead.type = SnakeBodyPart.SnakeBodyPartType.Body
        snakeHead = tempHead
        
        // Shift all positions, except the origin, by one starting from the last position
        for index in reverse(1 ..< snakeBody.count) {
            snakeBody[index] = snakeBody[index-1]
        }
        
        // Generate new origin
        let head = snakeHead
        //        if continuous {
        //            var newLocationX: Float = head.locationX
        //            var newLocationY: Float = head.locationY
        //
        //            switch head.direction {
        //            case .Up:
        //                (head.locationY - 1.0 < yLowerBound) ? (newLocationY = yUpperBound) : (newLocationY = head.locationY - 1)
        //            case .Down:
        //                (head.locationY + 1.0 > yUpperBound) ? (newLocationY = xLowerBound) : (newLocationY = head.locationY + 1)
        //            case .Right:
        //                (head.locationX + 1.0 > xUpperBound) ? (newLocationX = yLowerBound) : (newLocationX = head.locationX + 1)
        //            case .Left:
        //                (head.locationX - 1.0 < xLowerBound) ? (newLocationX = xUpperBound) : (newLocationX = head.locationX - 1)
        //            }
        //            snakeHead = SnakeBodyPart(x: newLocationX, y: newLocationY, direction: head.direction, type: SnakeBodyPart.SnakeBodyPartType.Head)
        //
        //        }else {
        var newLocationX: Float = head.locationX
        var newLocationY: Float = head.locationY
        
        switch head.direction {
        case .Up:
            newLocationY = head.locationY - 1.0
        case .Down:
            newLocationY = head.locationY + 1.0
        case .Right:
            newLocationX = head.locationX + 1.0
        case .Left:
            newLocationX = head.locationX - 1.0
        }
        snakeHead = SnakeBodyPart(x: newLocationX, y: newLocationY, direction: head.direction, type: SnakeBodyPart.SnakeBodyPartType.Head)
        //        }
        
        if let _delegate = delegate {
//            _delegate.snakeDidMove()
        }
        
    }
    
    func grow(){
        snakeBody.append(tailBodyPart)
    }
    
    func steer(direction: Direction) {
        snakeHead.direction = direction
    }
    
    func kill() {
        moveTimer.invalidate()
        moveTimerInterval = defaultmoveTimerInterval
        snakeBody.removeAll(keepCapacity: false)
    }
    
}