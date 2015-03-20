//
//  AppleMock.swift
//  SnakeSwift
//
//  Created by eandrade21 on 3/15/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import Foundation

class AppleMock: Apple {
    
    override var timerInterval: NSTimeInterval {
        get {
            return 0.2
        }
        set {
            super.timerInterval = newValue
        }
    }
}