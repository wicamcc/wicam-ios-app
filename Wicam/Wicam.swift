//
//  Wicam.swift
//  Wicam
//
//  Created by Yunfeng Liu on 2016-06-19.
//  Copyright © 2016 Armstart. All rights reserved.
//

import UIKit
import AVFoundation
import Starscream

class Wicam: NSObject, NSCoding, WebSocketDelegate {
    var fwVersion: Int8 = 0
    var ssid: String
    var password: String
    var ip: String
    var staSSID: String
    var staPassword: String
    var staSec: Int
    var lanIP: String = ""
    var wanIP: String
    var wanPort: Int

    
    var batteryLevel: Float = 0
    var temperatureLevel: Float = 0.0
    
    var isSignedIn: Bool = false
    var checkTimer: NSTimer?
    var socket: WebSocket?
    var socketQueue = dispatch_queue_create("co.armstart.wicam", nil)
    var socketState: State = .Disconnect
    
    var videoFileURL: NSURL?
    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?
    var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    var videoStartTime: CFTimeInterval = 0
    var frameCount:Int64 = 0
    var lastFrameTime: CMTime = CMTimeMake(0, 7)
    
    var upnpDev:UnsafeMutablePointer<UPNPDev> = nil
    
    var delegate: WicamDelegate?
    var storeDelegate: WicamStoreDelegate?
    
    static let SupportDirectory = NSFileManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first!
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("savedWicams.data")
    
    
    
    let SSID_MAX_LEN = 32
    let MAX_PIN_LEN = 12
    let MAIN_CONF_T_SIZE = 129
    let WANPORT_START = 4557
    let WANPORT_END = 4590
    
    enum State {
        case Disconnect
        case Connected
        case SignedIn
        case VideoMode
        case PictureMode
    }
    
    struct PropertyKey {
        static let SSID = "ssid"
        static let PASSWORD = "password"
        static let STASSID = "staSSID"
        static let STAPASSWORD = "staPassword"
        static let STASEC = "staSec"
        static let LANIP = "lanIP"
        static let WANIP = "wanIP"
        static let WANPORT = "wanPort"
    }
    
    init(ssid: String, ip: String, password: String = "", staSSID: String = "", staPassword: String = "", staSec: Int = 2, wanIP: String = "", wanPort: Int = 0) {
        self.ssid = ssid
        self.password = password
        self.ip = ip
        self.staSSID = staSSID
        self.staPassword = staPassword
        self.staSec = staSec
        self.wanIP = wanIP
        self.wanPort = wanPort
        
        super.init()
        
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let ssid = aDecoder.decodeObjectForKey(PropertyKey.SSID) as! String
        let password = aDecoder.decodeObjectForKey(PropertyKey.PASSWORD) as? String ?? ""
        let staSSID = aDecoder.decodeObjectForKey(PropertyKey.STASSID) as? String ?? ""
        let staPassword = aDecoder.decodeObjectForKey(PropertyKey.STAPASSWORD) as? String ?? ""
        let staSec = aDecoder.decodeIntegerForKey(PropertyKey.STASEC)
        let lanIP = aDecoder.decodeObjectForKey(PropertyKey.LANIP) as? String ?? ""
        let wanIP = aDecoder.decodeObjectForKey(PropertyKey.WANIP) as? String ?? ""
        let wanPort = aDecoder.decodeIntegerForKey(PropertyKey.WANPORT)
        
        self.init(ssid: ssid, ip: "", password: password, staSSID: staSSID, staPassword: staPassword, staSec: staSec, wanIP: wanIP, wanPort: wanPort)
        self.lanIP = lanIP
        
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(ssid, forKey: PropertyKey.SSID)
        aCoder.encodeObject(password, forKey: PropertyKey.PASSWORD)
        aCoder.encodeObject(staSSID, forKey: PropertyKey.STASSID)
        aCoder.encodeObject(staPassword, forKey: PropertyKey.STAPASSWORD)
        aCoder.encodeInteger(staSec, forKey: PropertyKey.STASEC)
        aCoder.encodeObject(wanIP, forKey: PropertyKey.WANIP)
        aCoder.encodeInteger(wanPort, forKey: PropertyKey.WANPORT)
    }
    
    // MARK: Websocket
    func connect() {
        if socketState == .Connected {
            delegate?.didConnectedWicam?(self)
            return;
        }
        print("connecting to \(ip)")
        socket = WebSocket(url: NSURL(string: "ws://" + ip)!)
        socket?.delegate = self
        socket?.callbackQueue = socketQueue
        socket?.connect()
        
    }
    
    func disconnect() {
        print("Wicam.disconnect")
        socket?.disconnect()
    }
    @objc func checkSignin() {
        if !isSignedIn {
            delegate?.didFailedSignInWicam?(self)
        }
    }
    func signin() {
        checkTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(Wicam.checkSignin), userInfo: nil, repeats: false)
        print("sending cmd: \("pwd:" + ssid + password)")
        print("length: \(("pwd:" + ssid + password).characters.count)")
        socket?.writeString("pwd:" + ssid + password)
        // set up timer to detect sign in failure
    }
    func startVideo() {
        // 
        let ct = CFAbsoluteTimeGetCurrent()
        videoFileURL = Wicam.DocumentsDirectory.URLByAppendingPathComponent(ssid + "_" + String(ct) + ".mov")
        do {
            try videoWriter = AVAssetWriter(URL: videoFileURL!, fileType: AVFileTypeQuickTimeMovie)
            print("videoWriter=\(videoWriter)")
            let outputSettings:[String: AnyObject]? = [AVVideoCodecKey:AVVideoCodecH264, AVVideoWidthKey:640, AVVideoHeightKey:480]
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
            print("videoWriterInput=\(videoWriterInput)")
            videoWriterInput?.expectsMediaDataInRealTime = true
            let sourcePixelBufferAttributes:[String: AnyObject] = [
                kCVPixelBufferPixelFormatTypeKey as String:Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String:640,
                kCVPixelBufferHeightKey as String:480,
            ]
            pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
            print("pixelBufferAdapter=\(pixelBufferAdapter)")
            if let r = videoWriter?.canAddInput(videoWriterInput!) {
                print("videoWriter.canAddInput \(r)");
            }
            videoWriter?.addInput(videoWriterInput!)
            if let r = videoWriter?.startWriting() {
                print("videoWriter.startWriting returned \(r)")
            }
            videoWriter?.startSessionAtSourceTime(kCMTimeZero)
            videoStartTime = CACurrentMediaTime()
            frameCount = 0
            
        } catch {
            return
        }
        socket?.writeString("vga")
        socket?.writeString("video")
        socketState = .VideoMode
    }
    func stopVideo() {
        socket?.writeString("pwd:" + ssid + password)
        print("Writer status: \(videoWriter?.status.rawValue)")
        lastFrameTime = CMTimeMake(0, 7)
        videoWriterInput?.markAsFinished()
        videoWriter?.finishWritingWithCompletionHandler({() -> Void in
            // TODO: add Video Stopped Callback
            dispatch_async(dispatch_get_main_queue()){
                self.delegate?.didVideoStopped?(self, url: self.videoFileURL)
            }
        })
    }
    func takePicture() {
        socket?.writeString("xga")
        socket?.writeString("picture")
        socketState = .PictureMode
    }
    func getBatteryLevel() {
        socket?.writeString("battery")
    }
    func getTemperature() {
        socket?.writeString("temperature")
    }
    
    
    func updateNewConfigToWicam() {
        //let config = NSMutableData(capacity: MAIN_CONF_T_SIZE)
        //config.repl
        
        let config = NSMutableData(length: 129)
        config?.replaceBytesInRange(NSRange(location: 0, length: 1), withBytes: &fwVersion, length: 1)
        config?.replaceBytesInRange(NSRange(location: 4, length: ssid.characters.count), withBytes: ssid)
        config?.replaceBytesInRange(NSRange(location: 4 + SSID_MAX_LEN + 1, length: password.characters.count), withBytes: password)
        config?.replaceBytesInRange(NSRange(location: 4 + SSID_MAX_LEN + MAX_PIN_LEN + 2, length: staSSID.characters.count), withBytes: staSSID)
        config?.replaceBytesInRange(NSRange(location: 4 + 2*SSID_MAX_LEN + MAX_PIN_LEN + 3, length: staPassword.characters.count), withBytes: staPassword)
        config?.replaceBytesInRange(NSRange(location: 4 + 2*SSID_MAX_LEN + 2*MAX_PIN_LEN + 4, length: 1), withBytes: &staSec, length: 1)
        
        print("Websocket sending new config")
        socket?.writeData(config!)
        
        
    }
    
    // MARK: WebSocketDelegate
    func websocketDidConnect(socket: WebSocket) {
        print("Wicam \(ssid) connected")
        dispatch_async(dispatch_get_main_queue()){
            self.socketState = .Connected
            self.delegate?.didConnectedWicam?(self)
        }
        
    }
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("NSData received \(data.length)")
        if data.length == MAIN_CONF_T_SIZE {
            guard let ap_ssid = String.fromCString(UnsafePointer<Int8>(data.subdataWithRange(NSRange(location: 4, length: SSID_MAX_LEN)).bytes)) else {
                return
            }
            guard let ap_pin = String.fromCString(UnsafePointer<Int8>(data.subdataWithRange(NSRange(location: 4 + SSID_MAX_LEN + 1, length: MAX_PIN_LEN)).bytes)) else {
                return
            }
            guard let sta_ssid = String.fromCString(UnsafePointer<Int8>(data.subdataWithRange(NSRange(location: 4 + SSID_MAX_LEN + MAX_PIN_LEN + 2, length: SSID_MAX_LEN)).bytes)) else {
                return
            }
            guard let sta_pin = String.fromCString(UnsafePointer<Int8>(data.subdataWithRange(NSRange(location: 4 + 2*SSID_MAX_LEN + MAX_PIN_LEN + 3, length: MAX_PIN_LEN)).bytes)) else {
                return
            }
            var version:Int8 = 0
            data.getBytes(&version, length: 1)
            print("Wicam firmware version: \(version)")
            dispatch_async(dispatch_get_main_queue()){
                self.fwVersion = version
                self.socketState = .SignedIn
                self.ssid = ap_ssid
                self.password = ap_pin
                self.staSSID = sta_ssid
                self.staPassword = sta_pin
                
                self.checkTimer?.invalidate()
                self.checkTimer = nil
                self.delegate?.didSignedInWicam?(self)
            }
            
            
        } else {
            if socketState == .PictureMode {
                guard let image = UIImage(data: data) else {
                    return
                }
                let ct = CFAbsoluteTimeGetCurrent()
                let file = Wicam.DocumentsDirectory.URLByAppendingPathComponent(ssid + "_" + String(ct) + ".jpg")
                data.writeToURL(file, atomically: true)
                dispatch_async(dispatch_get_main_queue()){
                    
                    self.delegate?.didReceivedPictureFromWicam?(self, frame: image, url:file)
                }
            } else if socketState == .VideoMode {
                guard let image = UIImage(data: data) else {
                    return
                }
                // encode and save to file
                print("Start encodeFrame")
                autoreleasepool {
                    encodeFrame(image)
                }
                print("End encodeFrame")
                dispatch_async(dispatch_get_main_queue()){
                    
                    self.delegate?.didReceivedVideoFromWicam?(self, frame: image)
                }
            }
            
        }
    }
    func encodeFrame(frame: UIImage) {
        
        // verify PixelBufferPool is valid
        guard let pixelBufferPool = pixelBufferAdapter?.pixelBufferPool else {
            print("pixelBufferPool nil")
            return
        }
        // Prepare CVPixelBuffer Pointer to use to create PixelBuffer from Pool
        let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
        let cvReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, pixelBufferPointer)
        guard let pixelBuffer = pixelBufferPointer.memory else {
            pixelBufferPointer.dealloc(1)
            print("pixelBuffer nil \(cvReturn)")
            return
        }
        if cvReturn != 0 {
            print("CVPixelBufferPoolCreatePixelBuffer error \(cvReturn)")
            pixelBufferPointer.destroy()
            pixelBufferPointer.dealloc(1)
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        
        let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapContext = CGBitmapContextCreate(pixelBufferBaseAddress, Int(frame.size.width), Int(frame.size.height), 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, frame.size.width, frame.size.height), frame.CGImage)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        
        let videoEndTime = CACurrentMediaTime()
        let videoDuration = videoEndTime - videoStartTime
        frameCount += 1
        //var fps:Int32 = Int32(Double(frameCount)/videoDuration)
        //if fps == 0 {
        //    fps = 7
        //}
        let fps:Int32 = 7
        print("frameCount=\(frameCount) duration= \(videoDuration) fps=\(fps)")
        let frameDuration = CMTimeMake(1, fps)
        let presentationTime = CMTimeAdd(lastFrameTime, frameDuration)
        lastFrameTime = presentationTime
        
        if let r = pixelBufferAdapter?.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime) {
            print("appPixelBuffer result \(r)")
        }
        pixelBufferPointer.destroy()
        pixelBufferPointer.dealloc(1)
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        dispatch_async(dispatch_get_main_queue()){
            print("Wicam: didDisconnect")
            self.socketState = .Disconnect
            self.isSignedIn = false
            self.delegate?.didDisconnectedWicam?(self)
        }
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        dispatch_async(dispatch_get_main_queue()){
            if text.hasPrefix("b=") {
                // TODO: This is battery level, convert the value
                let val:Float? = Float(text.substringFromIndex(text.startIndex.advancedBy(2)))
                guard let battery = val else {
                    return
                }
                self.batteryLevel = (battery*4.2)/633.623
                // FIXME: round up errors
                if self.batteryLevel > 4.15 {
                    self.batteryLevel = 4.2
                }
                
            } else if text.hasPrefix("t=") {
                // TODO: This is the temperature level, convert the value
                let val:Float? = Float(text.substringFromIndex(text.startIndex.advancedBy(2)))
                guard let temperature = val else {
                    return
                }
                self.temperatureLevel = temperature*0.22
            }
        }
    }
    
    // MARK: Remote access
    
    func upnpDiscovery() -> Bool {
        var upnpError: Int32 = 0
        if upnpDev != nil {
            freeUPNPDevlist(upnpDev)
            upnpDev = nil
        }
        upnpDev = upnpDiscover(2000, nil, nil, 0, 0, 2, &upnpError)
        if upnpDev == nil || upnpError != 0 {
            return false
        }
        return true
    }
    
    func upnpAddPortMapping(givenPort: Int = 0) -> Bool {
        var upnpUrls = UPNPUrls()
        var igdDatas = IGDdatas()
        if upnpDev == nil {
            return false
        }
        if ip == "192.168.240.1" || ip.isEmpty {
            return false
        }
        var appLanAddr: [Int8] = [Int8](count: 64, repeatedValue: 0)
        
        
        if UPNP_GetValidIGD(upnpDev, &upnpUrls, &igdDatas, &appLanAddr, 64) != 1 {
            FreeUPNPUrls(&upnpUrls)
            return false
        }
        var wanAddr: [Int8] = [Int8](count: 64, repeatedValue: 0)
        
        if (withUnsafeMutablePointer(&igdDatas.first.servicetype) { p -> Bool in
            if UPNP_GetExternalIPAddress(upnpUrls.controlURL, UnsafeMutablePointer<Int8>(p), &wanAddr) != 0 {
                return false
            }
            var portMapped = 0
            var startPort = WANPORT_START
            var endPort = WANPORT_END
            if givenPort != 0 {
                startPort = givenPort
                endPort = givenPort
            }
            for port in startPort...endPort {
                let tryWanPort = String(port)
                if UPNP_AddPortMapping(upnpUrls.controlURL, UnsafeMutablePointer<Int8>(p), tryWanPort, "80", ip, "Wicam UPNPC Port Mapping", "TCP", nil, nil) == 0 {
                    portMapped = port
                    break
                }
            }
            if portMapped == 0 {
                return false
            }
            self.wanPort = portMapped
            self.wanIP = String.fromCString(&wanAddr) ?? ""
            self.lanIP = ip
            print("Wicam port mapped: \(lanIP):80 --> \(wanIP):\(wanPort)")
            return true
        }) == false {
            FreeUPNPUrls(&upnpUrls)
            return false
        }
        //storeDelegate?.saveUpdatedWicam?(self)
        
        return true
        
    }
    
    func upnpRemovePortMapping() -> Bool {
        var upnpUrls = UPNPUrls()
        var igdDatas = IGDdatas()
        if upnpDev == nil {
            return false
        }
        if ip == "192.168.240.1" || ip.isEmpty {
            return false
        }
        
        if wanPort < WANPORT_START || wanPort > WANPORT_START {
            return false
        }
        
        var appLanAddr: [Int8] = [Int8](count: 64, repeatedValue: 0)
        
        if UPNP_GetValidIGD(upnpDev, &upnpUrls, &igdDatas, &appLanAddr, 64) != 1 {
            FreeUPNPUrls(&upnpUrls)
            return false
        }
        
        let wanPortStr = String(wanPort)
        
        if (withUnsafeMutablePointer(&igdDatas.first.controlurl){ p -> Bool in
            if UPNP_DeletePortMapping(upnpUrls.controlURL, UnsafeMutablePointer<Int8>(p), wanPortStr, "TCP", nil) != 0 {
                return false
            }
            self.wanPort = 0
            self.wanIP = ""
            return true
        }) == false {
            FreeUPNPUrls(&upnpUrls)
            return false
        }
        return true
    }
    

    
    // MARK: deinit
    
    deinit {
        if upnpDev != nil {
            freeUPNPDevlist(upnpDev)
            upnpDev = nil
        }
    }



}
