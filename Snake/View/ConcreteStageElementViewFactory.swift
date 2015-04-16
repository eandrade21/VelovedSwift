//
//  ConcreteStageElementViewFactory.swift
//  SnakeSwift
//
//  Created by eandrade21 on 4/14/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

protocol ConcreteStageElementViewFactory {
    typealias ElementView
    func stageElementView(#forElement: StageElement, transform: StageViewTransform) -> ElementView
}