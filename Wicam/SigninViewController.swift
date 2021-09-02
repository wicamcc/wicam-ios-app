//
//  ViewController.swift
//  Wicam
//
//  Created by Yunfeng Liu on 2016-06-19.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit


class SigninViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, WicamDelegate {
    
    // MARK: UI Properties

    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signinBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var warningLabel: UILabel!

    
    var wicam: Wicam?
    var wicamOldPassword: String?
    let segueChoosemode = "Choosemode"
    let segueUnwindToScanList = "unwindToScanList"


    override func viewDidLoad() {
        super.viewDidLoad()
        print("SigininViewController didLoad")
        passwordTextField.delegate = self
        ssidLabel.text = wicam!.ssid
        passwordTextField.text = wicam?.password
        wicam?.delegate = self
        if wicam?.ip == "192.168.240.1" {
            warningLabel.text = "Wicam is running in Hotspot mode. Please connect to " + wicam!.ssid + " Hotspot before signing in in app."
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI Actions
    @IBAction func signinBarButtonItem(sender: UIBarButtonItem) {
        print("Sign in Button clicked")
        doSignin()
        
    }


    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        doSignin()
        
        
        return true
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueChoosemode {
            let chooseModeController = segue.destinationViewController as! ChooseModeViewController
            chooseModeController.wicam = wicam
        }
    }
    
    // MARK: WicamDelegate
    
    func didConnectedWicam(wicam: Wicam) {
        print("Wicam connected")
        wicamOldPassword = wicam.password
        wicam.password = passwordTextField.text!
        wicam.signin()
        
    }
    func didDisconnectedWicam(wicam: Wicam) {
        // TODO: Alert then unwind back to List
        print("Wicam disconnected.")
        signinBarButtonItem.enabled = true
        let alert = UIAlertController(title: "Disconnected or Failed connecting", message: "We have failed signing into Wicam. It could be lost of connection or some exception happened. We will try going back to rescan. If you still cannot find Wicam. Try rebooting it manually.", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
            self.performSegueWithIdentifier(self.segueUnwindToScanList, sender: self)
        })
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    func didSignedInWicam(wicam: Wicam) {
        // TODO: segue to Choosemode
        print("Wicam signed in")
        signinBarButtonItem.enabled = true
        wicam.storeDelegate?.saveUpdatedWicam?(wicam)
        performSegueWithIdentifier(segueChoosemode, sender: self)
    }
    func didFailedSignInWicam(wicam: Wicam) {
        // TODO: Alert user failed.
        print("Failed signing into Wicam")
        signinBarButtonItem.enabled = true
        // This is to make sure we still have the right password if user accidently changed it and its wrong
        if let pwd = wicamOldPassword {
            wicam.password = pwd
        }
        let alert = UIAlertController(title: "Sign in failure", message: "Are you giving the wrong password? Try again.", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
        })
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: Helpers
    
    func doSignin() {
        // hide keyboard
        passwordTextField.resignFirstResponder();
        wicam?.delegate = self
        if let password = passwordTextField.text {
            if password.characters.count >= 8 {
                signinBarButtonItem.enabled = false
                wicam?.connect()
            } else {
                let alert = UIAlertController(title: "Password issue", message: "Password must be 8 or more characters long", preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                alert.addAction(ok)
                presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Password empty", message: "Password must be 8 or more characters long", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
            })
            alert.addAction(ok)
            presentViewController(alert, animated: true, completion: nil)
        }
        
    }

}

