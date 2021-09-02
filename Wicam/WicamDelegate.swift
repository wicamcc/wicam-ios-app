//
//  WicamDelegate.swift
//  Open Wicam
//
//  Created by Yunfeng Liu on 2016-08-22.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit

@objc protocol WicamDelegate {
    optional func didConnectedWicam(wicam: Wicam)
    optional func didDisconnectedWicam(wicam: Wicam)
    optional func didSignedInWicam(wicam: Wicam)
    optional func didFailedSignInWicam(wicam: Wicam)
    optional func didReceivedVideoFromWicam(wicam: Wicam, frame: UIImage)
    optional func didVideoStopped(wicam: Wicam, url: NSURL?)
    optional func didReceivedPictureFromWicam(wicam: Wicam, frame: UIImage, url: NSURL?)

}