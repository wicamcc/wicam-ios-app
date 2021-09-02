//
//  PictureModeViewController.swift
//  Open Wicam
//
//  Created by Yunfeng Liu on 2016-06-24.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit

class PictureModeViewController: UIViewController, WicamDelegate {
    
    // MARK: Properties
    

    @IBOutlet weak var photoView: UIImageView!
    var wicam: Wicam?
    
    let segue2Choosemode = "PicUnwind2Choosemode"
    let segueDisconnected = "PicDisconnectUnwind"

    override func viewDidLoad() {
        super.viewDidLoad()
        if wicam == nil {
            print("Wicam is nil")
        }
        wicam?.delegate = self

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
    @IBAction func imageViewTapped(sender: UITapGestureRecognizer) {
        print("Taking picture")
        wicam?.takePicture()
    }
    
    @IBAction func backUIBarButtonItem(sender: UIBarButtonItem) {
        performSegueWithIdentifier(segue2Choosemode, sender: self)
    }
    
    // MARK: WicamDelegate
    
    func didReceivedPictureFromWicam(wicam: Wicam, frame: UIImage, url: NSURL?) {
        print("Received picture from Wicam")
        photoView.image = frame
        
    }
    
    func didDisconnectedWicam(wicam: Wicam) {
        performSegueWithIdentifier(segueDisconnected, sender: self)
    }
    

}
