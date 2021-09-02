//
//  SettingViewController.swift
//  Open Wicam
//
//  Created by Yunfeng Liu on 2016-06-26.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController, WicamDelegate {
    
    // MARK: Properties
    
    var wicam: Wicam?
    
    var switchChanged: Bool = false
    
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var ssidTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var staSSIDTextField: UITextField!
    @IBOutlet weak var staPasswordTextField: UITextField!
    @IBOutlet weak var remoteSwitch: UISwitch!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    
    
    
    
    
    let segueToSave = "unwindToSave"

    override func viewDidLoad() {
        super.viewDidLoad()
        wicam?.delegate = self
        ssidLabel.text = wicam?.ssid
        ssidTextField.text = wicam?.ssid
        passwordTextField.text = wicam?.password
        staSSIDTextField.text = wicam?.staSSID
        staPasswordTextField.text = wicam?.staPassword
        batteryLabel.text = "Battery: " + String(format: "%.2f", (wicam?.batteryLevel)!) + "/4.2V"
        temperatureLabel.text = "Temperature: " + String(format: "%.2f", (wicam?.temperatureLevel)!)
        let wanAddr = (wicam?.wanIP)! + ":" + String(wicam?.wanPort)
        if (wicam?.ip == "192.168.240.1" || (wicam?.ip == wanAddr)) {
            remoteSwitch.enabled = false
        } else {
            remoteSwitch.enabled = true
            if wicam?.wanPort != 0 {
                remoteSwitch.on = true
            }
        }

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
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func validateAllFieldsAndSync () -> String {
        let newSSID = ssidTextField.text!
        let newPassword = passwordTextField.text!
        let newStaSSID = staSSIDTextField.text!
        let newStaPassword = staPasswordTextField.text!
        if newSSID.hasPrefix("WiCam-") == false {
            ssidTextField.text = wicam?.ssid
            return "Wicam name must start with 'WiCam-'"
        } else if newSSID.characters.count < 7 {
            ssidTextField.text = wicam?.ssid
            return "Wicam name must be at least 7 characters long"
        } else if newPassword.characters.count < 8 || newPassword.characters.count > 12 {
            passwordTextField.text = wicam?.password
            return "Wicam password must be between 8...12 characters"
        }
        wicam?.ssid = newSSID
        wicam?.password = newPassword
        wicam?.staSSID = newStaSSID
        wicam?.staPassword = newStaPassword
        return ""
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        let valResult = validateAllFieldsAndSync()
        if  valResult.isEmpty != true {
            let alert = UIAlertController(title: "Invalid changes", message: valResult, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "Got it", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
            })
            alert.addAction(ok)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if switchChanged == true {
            if remoteSwitch.on == true {
                EZLoadingActivity.show("Enabling WiCam's remote access", disableUI: true)
            } else {
                EZLoadingActivity.show("Disabling WiCam's remote access", disableUI: true)
            }
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                if self.wicam?.upnpDiscovery() == true {
                    if self.remoteSwitch.on == true {
                        if self.wicam!.upnpAddPortMapping() == true {
                            // TODO: save and return
                            dispatch_async(dispatch_get_main_queue()) {
                                EZLoadingActivity.hide()
                                self.wicam?.updateNewConfigToWicam()
                            }
                            return
                        }
                    } else {
                        if self.wicam!.upnpRemovePortMapping() == true {
                            // TODO: save and return
                            dispatch_async(dispatch_get_main_queue()) {
                                EZLoadingActivity.hide()
                                self.wicam?.updateNewConfigToWicam()
                            }
                            return
                        }
                    }
                    
                }
                // deal with error
                dispatch_async(dispatch_get_main_queue()) {
                    EZLoadingActivity.hide()
                    let alert = UIAlertController(title: "UPnP not enabled in router", message: "ERROR! It seems that the UPnP function is not enabled in your router. Wicam's remote access requires UPnP to be enabled to funcion properly. Therefore, remote access is not enabled at the moment.", preferredStyle: .Alert)
                    let ok = UIAlertAction(title: "Got it", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                        alert.dismissViewControllerAnimated(true, completion: nil)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    alert.addAction(ok)
                    self.presentViewController(alert, animated: true, completion: nil)
                    self.remoteSwitch.on = false
                }
            }
        } else {
            self.wicam?.updateNewConfigToWicam()
        }
        
    }
    
    func upnpAddPortSuccess() {
        dispatch_async(dispatch_get_main_queue()) {
            EZLoadingActivity.hide()
            print("@@@@@@@@@@@@@@ success @@@@@@@@@@@@@@@")
        }
    }
    
    @IBAction func remoteSwitchValueChanged(sender: UISwitch) {
        print("Remote Switch value \(sender.on)")
        switchChanged = true
    }
    
    
    // MARK: WicamDelegate
    
    func didDisconnectedWicam(wicam: Wicam) {
        print("@@@@@ Wicam disconnected")
        self.performSegueWithIdentifier(self.segueToSave, sender: self)
    }
    func didSignedInWicam(wicam: Wicam) {
        print("$$$$$$$$$$$$$$ Wicam received my config $$$$$$$$$$$$$$")
        print("\(wicam)")
        wicam.storeDelegate?.saveUpdatedWicam?(wicam)
        self.performSegueWithIdentifier(self.segueToSave, sender: self)
    }
    

}
