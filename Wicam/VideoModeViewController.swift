//
//  VideoModeViewController.swift
//  Open Wicam
//
//  Created by Yunfeng Liu on 2016-06-24.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit

class VideoModeViewController: UIViewController, WicamDelegate {

    // MARK: Properties
    
    var wicam: Wicam?
    
    @IBOutlet weak var videoImageView: UIImageView!
    
    let segueUnwind2Choosemode = "VideoUnwind2Choosemode"
    let segueDisconnectUnwind = "VideoDisconnectUnwind"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wicam?.delegate = self
        wicam?.startVideo()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Actions
    
    @IBAction func stopUIBarButtonItem(sender: UIBarButtonItem) {
        wicam?.stopVideo()
    }
    
    
    // MARK: WicamDelegate
    
    func didDisconnectedWicam(wicam: Wicam) {
        performSegueWithIdentifier(segueDisconnectUnwind, sender: self)
    }
    func didReceivedVideoFromWicam(wicam: Wicam, frame: UIImage) {
        videoImageView.image = frame
    }
    func didVideoStopped(wicam: Wicam, url: NSURL?) {
        if let videoURL = url {
            print("moving \(videoURL.absoluteString) to Camera roll")
            UISaveVideoAtPathToSavedPhotosAlbum(videoURL.absoluteString, nil, nil, nil)
        }
        performSegueWithIdentifier(segueUnwind2Choosemode, sender: self)
    }

}
