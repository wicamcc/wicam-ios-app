//
//  WicamStoreDelegate.swift
//  Open Wicam
//
//  Created by Yunfeng Liu on 2016-08-23.
//  Copyright © 2016 Armstart. All rights reserved.
//

import Foundation

@objc protocol WicamStoreDelegate {
    optional func saveUpdatedWicam(wicam: Wicam)
}