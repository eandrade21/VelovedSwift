//
//  iOS_InfoAlertController.swift
//  GameSwift
//
//  Created by eandrade21 on 6/21/15.
//  Copyright (c) 2015 PartyLand. All rights reserved.
//

import UIKit
import GameCommon

enum iOS_InfoAlertControllerType {
    case Crashed
    case Won
}


class iOS_InfoAlertController: NSObject {

    class func getInfoAlertController(type: iOS_InfoAlertControllerType, backActionHandler: ((UIAlertAction!) -> Void), retryActionHandler: ((UIAlertAction!) -> Void)) -> UIAlertController {
        var alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.Alert)

        configureBackAction(alertController, backActionHandler: backActionHandler)
        configureRetryAction(alertController, retryActionHandler: retryActionHandler)
        configureAlerts(alertController, type: type)
        return alertController
    }

    private class func configureBackAction(alertController: UIAlertController, backActionHandler: ((UIAlertAction!) -> Void)) {
        let backAction = UIAlertAction(title: InfoAlertMainMenuActionTitle,
            style: UIAlertActionStyle.Default,
            handler: backActionHandler)

        alertController.addAction(backAction)
    }

    private class func configureRetryAction(alertController: UIAlertController, retryActionHandler: ((UIAlertAction!) ->  Void)) {
        let retryAction = UIAlertAction(title: InfoAlertRaceActionTitle,
            style: UIAlertActionStyle.Default,
            handler: retryActionHandler)

        alertController.addAction(retryAction)
    }

    private class func configureAlerts(alertController: UIAlertController, type: iOS_InfoAlertControllerType) {
        switch type {
        case .Crashed:
            configureCrashedAlert(alertController)
        case .Won:
            configureWonAlert(alertController)
        }
    }

    private class func configureCrashedAlert(alertController: UIAlertController) {
        let attributedTitle = getAlertAttributedString(InfoAlertCrashedTitle,
            fontName: DefaultAppFontNameHeavy,
            fontSize: InfoAlertTitleFontSize)
        alertController.setValue(attributedTitle, forKey: "attributedTitle")

        let attributedMessage = getAlertAttributedString(InfoAlertCrashedMessage,
            fontName: DefaultAppFontNameLight,
            fontSize: InfoAlertMessageFontSize)
        alertController.setValue(attributedMessage, forKey: "attributedMessage")

        alertController.actions.map() { ($0 as UIAlertAction).enabled = false }


        alertController.view.tintColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
    }

    private class func configureWonAlert(alertController: UIAlertController) {
        let attributedTitle = getAlertAttributedString(InfoAlertWonTitle,
            fontName: DefaultAppFontNameHeavy,
            fontSize: InfoAlertTitleFontSize)
        alertController.setValue(attributedTitle, forKey: "attributedTitle")

        let attributedMessage = getAlertAttributedString(InfoAlertWonMessage,
            fontName: DefaultAppFontNameLight,
            fontSize: InfoAlertMessageFontSize)
        alertController.setValue(attributedMessage, forKey: "attributedMessage")

        alertController.view.tintColor = UIColor.blackColor()
    }

    private class func getAlertAttributedString(text: String, fontName: String, fontSize: CGFloat) -> NSMutableAttributedString {
        var attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSFontAttributeName,
            value: UIFont(name: fontName, size: fontSize)!,
            range: NSRange(location: 0, length: countElements(text)))

        attributedString.addAttribute(NSForegroundColorAttributeName,
            value: UIColor.blackColor(),
            range: NSRange(location: 0, length: countElements(text)))
        
        return attributedString
    }

    class func updateInfoAlertController(alertController: UIAlertController) {
        alertController.actions.map() { ($0 as UIAlertAction).enabled = true }
        alertController.view.tintColor = UIColor.blackColor()

        let attributedMessage = getAlertAttributedString(InfoAlertUpdateCrashedMessage,
            fontName: DefaultAppFontNameLight,
            fontSize: InfoAlertMessageFontSize)
        alertController.setValue(attributedMessage, forKey: "attributedMessage")

    }
    
}