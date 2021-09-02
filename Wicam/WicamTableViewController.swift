//
//  WicamTableViewController.swift
//  Wicam
//
//  Created by Yunfeng Liu on 2016-06-19.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit
import CoreBluetooth
import CocoaAsyncSocket
import FileBrowser
import Darwin.C

class WicamTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate, GCDAsyncUdpSocketDelegate, WicamStoreDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var mediaUIBarButtonItem: UIBarButtonItem!
    
    var wicams = [Wicam]()
    
    var cbPeripherals = [CBPeripheral]()
    
    var centralState = CBCentralManagerState.Unknown
    
    var cbCentralManager: CBCentralManager!
    var peripheralsBLE = [CBPeripheral]()
    
    var listenSock: GCDAsyncUdpSocket?
    let LISTEN_PORT:UInt16 = 4277
    let BROADCAST_IP = "255.255.255.255"
    var sendSock: GCDAsyncUdpSocket?
    let SEND_PORT:UInt16 = 4211
    var discoveryQueue = dispatch_queue_create("co.armstart.wicam.discovery", nil)
    
    let DISCOVERY_PACKET_SIZE = 69
    let SSID_LEN_MAX = 32
    let IP_LEN_MAX = 15
    
    let cellID = "WicamTableViewCell"
    let segueSignin = "Signin"
    
    //let SERVICE_UUID = "5d98be76-f047-4D92-91f8-e6e4c25a98db"
    let SERVICE_UUID = "5D98BE76-F047-4D92-91F8-E6E4C25A98DB"
    let SERVICE_UUID_REV = "DB985AC2-E4E6-F891-924D-47F076BE985D"
    
    let VOLT_UUID = "5d98be76-f048-4D92-91f8-e6e4c25a98db"
    
    let IP_UUID = "5D98BE76-F049-4D92-91F8-E6E4C25A98DB"
    
    let SSID_UUID = "5D98BE76-F04A-4D92-91F8-E6E4C25A98DB"
    
    let DEBUG_UUID = "5d98be76-f04b-4D92-91f8-e6e4c25a98db"
    
    let TEMP_UUID = "5d98be76-f04c-4D92-91f8-e6e4c25a98db"
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        print("Load sample")
        
        if let wicams = loadWicams() {
            self.wicams = wicams
            print("Found \(wicams.count) saved Wicams")

        } else {
            print("No saved wicams")
        }
        
        
        cbCentralManager = CBCentralManager(delegate: self, queue: nil)
        
        
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return wicams.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! WicamTableViewCell
        
        
        // Configure the cell...
        
        let wicam = wicams[indexPath.row]
        
        cell.ssidLabel.text = wicam.ssid
        cell.selectionStyle = .Default
        cell.userInteractionEnabled = true
        
        print("render cell \(indexPath.row) \(wicam.ssid)")
        print("cell is remote: \(wicam.wanIP):\(wicam.wanPort)")
        
         if wicam.ip == "192.168.240.1" {
            print("Wicam IP is AP");
            cell.ssidLabel.text = "[Hotspot] " + wicam.ssid
        } else if wicam.ip.isEmpty && wicam.wanPort != 0 {
            print("Wicam IP is remote");
            wicam.ip = wicam.wanIP + ":" + String(wicam.wanPort)
            cell.ssidLabel.text = "[Remote] " + wicam.ssid
         } else if wicam.ip == "" {
            print("Wicam IP is empty");
            cell.ssidLabel.text = "[Offline] " + wicam.ssid
            cell.selectionStyle = .None
            cell.userInteractionEnabled = false
         } else {
            print("Wicam IP is Home");
            cell.ssidLabel.text = "[Home] " + wicam.ssid
        }

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        print("prepare \(segue.identifier), \(segue.destinationViewController)")
        
        if segue.identifier == segueSignin {
            let signinViewController = segue.destinationViewController as! SigninViewController
            let cell = sender as! WicamTableViewCell

            let indexPath = tableView.indexPathForCell(cell)!
            let wicam = wicams[indexPath.row]
            print("Assigning wicam to signinViewController")
            signinViewController.wicam = wicam
        }
 

    }
    

    @objc func stopScanning() {
        //cbCentralManager.stopScan()
        EZLoadingActivity.hide()
        // Stop BLE scanning
        cbCentralManager.stopScan()
        // disconnect connected BLE peripherals
        for peripheral in cbPeripherals {
            cbCentralManager.cancelPeripheralConnection(peripheral)
        }
        cbPeripherals.removeAll()
        // Close UDP discovery sockets
        listenSock?.closeAfterSending()
        sendSock?.closeAfterSending()
    }
    

    func startScanning() {
        print("start Scanning")
        stopScanning()
        
        EZLoadingActivity.show("Searching WiCams...", disableUI: true)
        
        
        listenSock = GCDAsyncUdpSocket(delegate: self, delegateQueue: discoveryQueue)
        listenSock?.setDelegate(self)
        sendSock = GCDAsyncUdpSocket(delegate: self, delegateQueue: discoveryQueue)
        sendSock?.setDelegate(self)
        do {
            listenSock?.setIPv4Enabled(true)
            listenSock?.setIPv6Enabled(false)
            listenSock?.setPreferIPv4()
            try listenSock?.bindToPort(LISTEN_PORT);
            try listenSock?.enableBroadcast(true)
            try listenSock?.beginReceiving()
            
            sendSock?.setIPv4Enabled(true)
            sendSock?.setIPv6Enabled(false)
            sendSock?.setPreferIPv4()
            try sendSock?.enableBroadcast(true)
            
            let msgWicam = "WiCam".dataUsingEncoding(NSUTF8StringEncoding)
            sendSock?.sendData(msgWicam!, toHost: BROADCAST_IP, port: SEND_PORT, withTimeout: 0, tag: 0)
            print("Sent UDP broadcast \(msgWicam)")
            // rescanning after 10 secs
            NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(WicamTableViewController.stopScanning), userInfo: nil, repeats: false)
            
        } catch let error as NSError {
            print(error);
        }
 

        
        // BLE scan
        if cbCentralManager.state == .PoweredOn {
            print("start scanning BLE")
            cbCentralManager.scanForPeripheralsWithServices([CBUUID(string: SERVICE_UUID_REV)], options: nil)
            print("start scanning BLE started")
        }
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print("View Did Appear")
        // Do UDP Scanning

    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print("View Did Disappear")
        let selectedIndex = tableView.indexPathForSelectedRow
        if let index = selectedIndex {
            tableView.deselectRowAtIndexPath(index, animated: false)
        }
        stopScanning()
        
    }

    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {

        switch central.state {
        case .Unknown:
            print("BLE Unknown")
        case .Resetting:
            print("BLE Resetting")
        case .Unsupported:
            print("BLE Unsupported")
        case .Unauthorized:
            print("BLE Unauthorized")
        case .PoweredOff:
            print("BLE PoweredOff")
        case .PoweredOn:
            print("BLE PoweredOn")
            // [CBUUID(string: SERVICE_UUID_REV)]
            //cbCentralManager.scanForPeripheralsWithServices([CBUUID(string: SERVICE_UUID_REV)], options: nil)
            
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("BLE discovered \(peripheral)")
        if peripheral.name != nil {
            cbPeripherals.append(peripheral)
            cbCentralManager.connectPeripheral(peripheral, options: nil)
            print("waiting for connected")
        }
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("BLE disconnected \(peripheral.name)")
        guard let index = cbPeripherals.indexOf(peripheral) else {
            return
        }
        cbPeripherals.removeAtIndex(index)
        
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Failed connecting \(peripheral) with error \(error)")
        guard let index = cbPeripherals.indexOf(peripheral) else {
            return
        }
        cbPeripherals.removeAtIndex(index)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("BLE connected. \(peripheral.name)")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID)])
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let err = error {
            print("BLE service discovery error. \(err.description)")
            return
        }
       
        guard let services = peripheral.services else {
            return
        }
        if (services.count != 1) {
            return
        }
        print("BLE \(peripheral.identifier.UUIDString) found service \(services[0].UUID.UUIDString)")
        let chars = [CBUUID(string: IP_UUID), CBUUID(string: SSID_UUID)]
        peripheral.discoverCharacteristics(chars, forService: services[0])
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let err = error {
            print("BLE characteristics discovery error. \(err.description)")
            return
        }
        print("Discovered Characteristics \(service.characteristics)")
        guard let chars = service.characteristics else {
            return
        }
        if chars.count < 2 {
            return   // wait for more discoveries so that we could retrieve values all in once.
        }
        peripheral.readValueForCharacteristic(chars[0])
        peripheral.readValueForCharacteristic(chars[1])
        
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Did Update Value for Char \(characteristic)")
        guard let services = peripheral.services else {
            return
        }
        guard let chars = services[0].characteristics else {
            return
        }
        if chars.count < 2 {
            return
        }
        
        if chars[0].value == nil || chars[1].value == nil {
            return
        }
        var newIP: String? = nil
        var newSSID: String? = nil
        for char in chars {
            if char.UUID.UUIDString == SSID_UUID {
                newSSID = String.fromCString(UnsafePointer<Int8>(char.value!.bytes))
            } else if (char.UUID.UUIDString == IP_UUID) {
                var data = [UInt8](count: 4, repeatedValue: 0)
                char.value!.getBytes(&data, length: 4)
                if data[0] == 0x0 {
                    print("IP field is zero. Wicam is running in AP mode.")
                    newIP = "192.168.240.1"
                } else {
                    newIP = String(format: "%d.%d.%d.%d", data[3], data[2], data[1], data[0])
                    print("IP field found \(newIP!). Wicam is running in STA mode.")
                }
            }
        }
        guard let foundIP = newIP, foundSSID = newSSID else {
            return
        }
        var found = false
        for (index, wicam) in wicams.enumerate() {
            if wicam.ssid != foundSSID {
                continue
            }
            print("Found existing Wicam (\(wicam.ssid) \(wicam.ip)).")
            if wicam.ip.isEmpty || wicam.ip == wicam.wanIP + ":" + String(wicam.wanPort) {
                print("Update it from BLE (\(foundSSID) \(foundIP))")
                wicam.ip = foundIP
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
            }
            found = true
            break
        }
        if !found {
            print("Found new Wicam. Add it from BLE")
            let indexPath = NSIndexPath(forRow: wicams.count, inSection: 0)
            let wicam = Wicam(ssid: foundSSID, ip: foundIP)
            wicam.storeDelegate = self
            wicams.append(wicam)
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
        }
        EZLoadingActivity.hide()
    }
    
    func udpSocketDidReceivedData(data: NSData) {
        // Parse the data and check & match Wicam object, then add it to the array
        
        
        guard let ip = String.fromCString(UnsafePointer<Int8>(data.subdataWithRange(NSRange(location: 1, length: IP_LEN_MAX)).bytes)) else {
            return
        }
        guard let ssid = String.fromCString(UnsafePointer<Int8>(data.subdataWithRange(NSRange(location: 17, length: SSID_LEN_MAX)).bytes)) else {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            var found = false
            for (index, wicam) in self.wicams.enumerate() {
                if wicam.ssid != ssid {
                    continue
                }
                print("Found existing Wicam. Update it with \(ip)")
                // TODO: If UPnP mapping exist, and IP is not right, then remap it.
                wicam.ip = ip
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
                found = true
                break
            }
            if !found {
                print("Found new Wicam. Add it \(ssid.characters.count) \(ssid) \(ip)")
                let indexPath = NSIndexPath(forRow: self.wicams.count, inSection: 0)
                let wicam = Wicam(ssid: ssid, ip: ip)
                wicam.storeDelegate = self
                self.wicams.append(wicam)
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
            }
            EZLoadingActivity.hide()
        }

    }
    
    // MARK: GCDAsyncUdpSocketDelegate
    
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress address: NSData, withFilterContext filterContext: AnyObject?) {
        print("received UDP")
        if data.length != DISCOVERY_PACKET_SIZE{
            return
        }
        var fromAddr: NSString?
        var fromPort: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&fromAddr, port: &fromPort, fromAddress: address)
        print("Udp broadcast received \(fromAddr!):\(fromPort). Data length:\(data.length)")
        print("Packet: \(data)")
        udpSocketDidReceivedData(data)
        
        
    }
    
    // MARK: WicamStoreDelegate
    
    func saveUpdatedWicam(wicam: Wicam) {
        if wicams.indexOf(wicam) == nil {
            print("save wicam. Wicam not found")
            return
        }
        saveWicams()
        
    }
    
    // MARK: Unwind
    
    
    @IBAction func unwindFromSigninViewControllerCancel(segue: UIStoryboardSegue) {
        wicams.removeAll()
        if let wicams = loadWicams() {
            self.wicams = wicams
            print("Found \(wicams.count) saved Wicams")
            
        } else {
            print("No saved wicams")
        }
        tableView.reloadData()
        startScanning()
    }
    
    @IBAction func unwindFromChooseModeViewControllerDisconnect(segue: UIStoryboardSegue) {
        wicams.removeAll()
        if let wicams = loadWicams() {
            self.wicams = wicams
            print("Found \(wicams.count) saved Wicams")
            
        } else {
            print("No saved wicams")
        }
        tableView.reloadData()
        startScanning()
    }
    
    
    // MARK: NSCoding
    
    func saveWicams() {
        print("saveWIcams")
        let isSaveSuccess = NSKeyedArchiver.archiveRootObject(wicams, toFile: Wicam.ArchiveURL.path!)
        if !isSaveSuccess {
            print("Failed to save Wicams \(wicams)")
        }
    }
    
    func loadWicams() -> [Wicam]? {
        let wicams = NSKeyedUnarchiver.unarchiveObjectWithFile(Wicam.ArchiveURL.path!) as? [Wicam]
        guard let wcs = wicams else {
            return wicams
        }
        for wicam in wcs {
            wicam.storeDelegate = self
        }
        return wicams
    }
    
    // MARK: Actions
    
    @IBAction func mediaButtonClicked(sender: UIBarButtonItem) {
        let fileBrowser = FileBrowser()
        self.presentViewController(fileBrowser, animated: true, completion: nil)
        //let imagePickerController = UIImagePickerController()
        //imagePickerController.sourceType = .PhotoLibrary
        //imagePickerController.delegate = self
        //presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func scanButtonClicked(sender: UIBarButtonItem) {
        startScanning()
    }
    

    
    

}
