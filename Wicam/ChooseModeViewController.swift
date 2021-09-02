//
//  ChooseModeViewController.swift
//  Wicam
//
//  Created by Yunfeng Liu on 2016-06-19.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit

class ChooseModeViewController: UIViewController, UINavigationControllerDelegate, WicamDelegate {
    
    // MARK: Notes
    //http://www.theappguruz.com/blog/integrating-media-player-ios-using-swift
    
    // MARK: Properties
    
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var settingsBarButtonItem: UIBarButtonItem!
    
    
    var wicam: Wicam?
    
    let segueUnwindToDisconnect = "unwindToDisconnect"
    let segueToPicturemode = "segueToPicturemode"
    let segueToVideomode = "segueToVideomode"
    let segueToSetting = "segueToSetting"


    override func viewDidLoad() {
        super.viewDidLoad()
        wicam?.delegate = self
        ssidLabel.text = wicam?.ssid
        wicam?.getBatteryLevel()
        wicam?.getTemperature()
        
        if (wicam!.ip == wicam!.wanIP + ":" + String(wicam!.wanPort)) {
            settingsBarButtonItem.enabled = false
        } else {
            settingsBarButtonItem.enabled = true
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        if wicam?.socketState == .Disconnect {
            didDisconnectedWicam(wicam!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == segueToPicturemode {
            let pictureModeViewController = segue.destinationViewController as! PictureModeViewController
            print("Picture mode wicam assigned")
            pictureModeViewController.wicam = wicam
        } else if segue.identifier == segueToVideomode {
            let videoModeViewController = segue.destinationViewController as! VideoModeViewController
            videoModeViewController.wicam = wicam
        } else if segue.identifier == segueToSetting {
            let nav = segue.destinationViewController as! UINavigationController
            let settingViewController = nav.viewControllers[0] as! SettingViewController
            settingViewController.wicam = wicam
        }
    }
    
    @IBAction func unwindFromVideoModeViewController(segue: UIStoryboardSegue) {
        wicam?.delegate = self
        if wicam?.socketState == .Disconnect {
            didDisconnectedWicam(wicam!)
        }
    }
    
    @IBAction func unwindFromPictureModeViewController(segue: UIStoryboardSegue) {
        wicam?.delegate = self
        if wicam?.socketState == .Disconnect {
            didDisconnectedWicam(wicam!)
        }
    }
    
    @IBAction func unwindFromSettingViewControllerSave(segue: UIStoryboardSegue) {
        print("unwind from setting")
        wicam?.delegate = self
        // fix for Websocket bug, when server disconnects, disconnect event not triggered
        wicam?.disconnect()
        didDisconnectedWicam(wicam!)
    }
    

    
    // MARK: Actions
    
    @IBAction func disconnectUIBarButtonItem(sender: UIBarButtonItem) {
        wicam?.delegate = self
        wicam?.disconnect()
    }
    
    // MARK: WicamDelegate
    
    func didDisconnectedWicam(wicam: Wicam) {
        performSegueWithIdentifier(segueUnwindToDisconnect, sender: self)
    }
    
    
    

}
