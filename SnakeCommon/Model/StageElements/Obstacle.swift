//
//  Obstacle.swift
//  SnakeSwift
//
//  Created by eandrade21 on 3/11/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import Foundation

public class Obstacle: StageElement {
    
    
}

extension Obstacle: StageLocationDescription {
    override var locationDesc: String {
        return "+"
    }
}