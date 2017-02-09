//
//  ViewController.swift
//  Smartie
//
//  Copyright © 2016 Smartbotics. All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    // BLE
    var centralManager : CBCentralManager!
    var SBLightPeripherals = [CBPeripheral!]()
    var SBLightDimmerFoundPeripherals = [CBPeripheral!]()
    var SBLightDimmerConnectedPeripherals = [CBPeripheral!]()
    var SBLightPeripheral : CBPeripheral!
    
    // Smartbotics UUIDs
    let SBLightServiceUUID = CBUUID(string: "FF10")
    let SBSwitchDataUUID = CBUUID(string: "FF11")
    let SBDimmerDataUUID = CBUUID(string: "FF12")
    
    // App Control
    var allowDeviceWrites : Bool = true
    var deviceAccessed : Bool = true
    var deviceConnected : Bool = false
    var noActivityTrigger : Int16 = 0
    var dimmerchanged : Bool = false
    var noActivityDisconnect : Bool = false
    
    @IBOutlet var Dimmer: UISlider!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Initialize central manager on load
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(ViewController.appMovedToBackground), name: UIApplicationWillResignActiveNotification, object: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.watchdog()
    }
    
    func appMovedToBackground() {
        print("App moved to background!")
        self.closedown()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillDisappear(animated: Bool) {
        print ("Disconnect from all peripherals")
        super.viewWillDisappear(animated)
        
    }
    
    
    @IBAction func DimmerSlider(sender: UISlider) {
            dimmerchanged = true
            print(self.allowDeviceWrites)
            if self.allowDeviceWrites {
        self.allowDeviceWrites = false
        var dimmerValue : Int
        dimmerValue = Int(sender.value)
        if (dimmerValue <= 5) {
                dimmerValue = 0
        }
        if dimmerValue >= 250 {
            dimmerValue = 255
        }
        print("value = \(dimmerValue)")
        let SmartboticsDeviceList = centralManager.retrieveConnectedPeripheralsWithServices([SBLightServiceUUID])
        print ("\(SmartboticsDeviceList)")
        //Sort through all Smartbotics devices
        if (SBLightDimmerConnectedPeripherals.count > 0) {
            for device in SBLightDimmerConnectedPeripherals {
            if (SmartboticsDeviceList.contains(device)) {
            print("for device in SmartboticsDeviceList \(device)")
            //sort through all services of each device
            for service in device.services! {
                print("for service in device.services!")
                if service.UUID == SBLightServiceUUID {
                print("if service.UUID == SBLightServiceUUID")
                // sort through all characteristics of each service
                for characteristic in service.characteristics! {
                    print("for characteristic in service.characteristics!")
                    if characteristic.UUID == SBDimmerDataUUID {
                    print("if characteristic.UUID == SBDimmerDataUUID")
                    //convert number to NSData
                    let writedata = NSData(bytes: &dimmerValue, length: sizeof(Int8))
                    device.writeValue(writedata, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
                    self.deviceAccessed = true
                    self.dimmerchanged = false
                    
                    }
                    
                    
                }
                
                }
                
            }
            
        }else{
            self.centralManager.connectPeripheral(device, options: nil)
            }
            }
        } else {
            if centralManager.state == CBCentralManagerState.PoweredOn {
                // Scan for peripherals if BLE is turned on
                centralManager.scanForPeripheralsWithServices([SBLightServiceUUID], options: nil)
                self.statusLabel.text = "Searching for Smartbotics Devices"
                // Stop Scanning after 8 seconds
                let delay = 20 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
                    // Stop scanning
                    self.centralManager.stopScan()
                    print("stopScan")
                }
            }
                else {
                // Can have different conditions for all states if needed - print generic message for now
                self.statusLabel.text = "Please turn Bluetooth on in Settings"
                print("Bluetooth switched off or not initialized")
            }
        }
        // after a delay allow writes again
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            // After 150 milliseconds this code will be executed
            self.allowDeviceWrites = true
        }
            }
            
    }
    
    
    @IBAction func Scan(sender: UIButton) {
                print("Scan Pressed")
                if centralManager.state == CBCentralManagerState.PoweredOn {
        // Scan for peripherals if BLE is turned on
        centralManager.scanForPeripheralsWithServices([SBLightServiceUUID], options: nil)
        self.statusLabel.text = "Searching for Smartbotics Devices"
        // Stop Scanning after 8 seconds
        let delay = 20 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            // Stop scanning
            self.centralManager.stopScan()
            self.statusLabel.text = "Connected to " + ("\(self.SBLightDimmerConnectedPeripherals.count)") + " devices"
            print("stopScan")
        }
    }
        else {
        // Can have different conditions for all states if needed - print generic message for now
        self.statusLabel.text = "Please turn Bluetooth on in Settings"
        print("Bluetooth switched off or not initialized")
                }
    }
    
    
    /******* CBCentralManagerDelegate *******/
     
     // Check status of BLE hardware
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("centralManagerDidUpdateState")
        if central.state == CBCentralManagerState.PoweredOn {
        // Scan for peripherals if BLE is turned on
        central.scanForPeripheralsWithServices([SBLightServiceUUID], options: nil)
        self.statusLabel.text = "Searching for Smartbotics Devices"
        // Stop Scanning after 8 seconds
        let delay = 20 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            // Stop scanning
            self.centralManager.stopScan()
            print("stopScan")
        }
     }
        else {
        // Can have different conditions for all states if needed - print generic message for now
        self.statusLabel.text = "Please turn Bluetooth on in Settings"
        print("Bluetooth switched off or not initialized")
        }
    }
    
    
    // Check out the discovered peripherals to find Smartbotics Devices
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? String
        print("didDiscoverPeripheral Smartbotics \(nameOfDeviceFound)")
        print("\(RSSI)")
        if (Double(RSSI) >= -77) {
            if (nameOfDeviceFound == nil) {
            self.statusLabel.text = ("Found Device with no Name")
        } else {
            // Update Status Label
            self.statusLabel.text = ("Found" + nameOfDeviceFound!)
            }
            // Set as the peripheral to use and establish connection
            for SBPeripheral in SBLightPeripherals {
                if (SBPeripheral == peripheral) {
                break;
                }
            }
            self.SBLightPeripherals.append(peripheral)
            self.SBLightPeripheral = peripheral
            self.SBLightPeripheral.delegate = self
            self.centralManager.connectPeripheral(peripheral, options: nil)
        }
    }
    
    // Discover services of the peripheral
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
            print("didConnectPeripheral \(peripheral)")
            self.statusLabel.text = "Connecting to \(peripheral.name!)"
            peripheral.discoverServices([SBLightServiceUUID])
    }
    
    
    // If disconnected, print out a message to log
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if (noActivityDisconnect) {
        var removeIndex = -1
        print("didDisconnectPeripheral \(peripheral)")
        print("\(SBLightDimmerConnectedPeripherals)")
        if !(SBLightDimmerConnectedPeripherals.count == 0) {
            for index in 0...((SBLightDimmerConnectedPeripherals.count - 1)) {
            if (SBLightDimmerConnectedPeripherals[index] == peripheral) {
            removeIndex = index
            }
            }
            if (removeIndex > -1) {
                SBLightDimmerConnectedPeripherals.removeAtIndex(removeIndex)
            }
        }
        print("\(SBLightDimmerConnectedPeripherals)")
        self.statusLabel.text = "Connected to " + ("\(SBLightDimmerConnectedPeripherals.count)") + " devices"
        if (SBLightDimmerConnectedPeripherals.count == 0) {
                self.deviceConnected = false
                self.noActivityTrigger = 0
                noActivityDisconnect = false
        }
    } else {
        self.centralManager.connectPeripheral(peripheral, options: nil)
        print("Reconnect Attempt Peripheral \(peripheral)")
        }
    }
    
    /******* CBCentralPeripheralDelegate *******/
     
     // Check if the service discovered is a valid Smartbotics Light Device
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices \(peripheral)")
        for service in peripheral.services! {
        let thisService = service as CBService
        if service.UUID == SBLightServiceUUID {
        // Discover characteristics of Smartbotics Light Service
        peripheral.discoverCharacteristics([SBDimmerDataUUID], forService: thisService)
        }
        // Print list of UUIDs
        print(thisService.UUID)
        }
    }
    
    
    // If Characteristic discovered read the value
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?)  {
        print("didDiscoverCharacteristicsForService \(peripheral)")
        // update status label
        
        // check the uuid of each characteristic to find smartbotics data characteristics
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            // check for data characteristic
            if thisCharacteristic.UUID == SBDimmerDataUUID {
            // Read Light Status
            peripheral.readValueForCharacteristic(thisCharacteristic)
            self.SBLightDimmerConnectedPeripherals.append(peripheral)
            self.deviceConnected = true
            }
            print(thisCharacteristic)
        }
        
    }
    
    
    
    // Get data values when they are read or notified update
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateValueForCharacteristic")
        self.statusLabel.text = "Connected to " + ("\(SBLightDimmerConnectedPeripherals.count)") + " devices"
        if characteristic.UUID == SBDimmerDataUUID {
        // Convert NSData to array of signed 16 bit values
        let dataBytes = characteristic.value
        var out: NSInteger = 0
        dataBytes!.getBytes(&out, length: sizeof(NSInteger))
        if (dimmerchanged) {
            var dimmerValue = self.Dimmer.value
            let writedata = NSData(bytes: &dimmerValue, length: sizeof(Int8))
            peripheral.writeValue(writedata, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
            self.deviceAccessed = true
            self.dimmerchanged = false
        }else {
            self.Dimmer.value = Float(out)
        }
        }
    }
    
    
    // Needed to add verify in order to get this data to write successfully
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didWriteValueForCharacteristic")
        
    }
    
    
    
    func watchdog () {
        // run watchdog every 1 second
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
        // Determine if app should stay disconnect from devices if there is no activity for 7 seconds
        print ("Watchdog \(self.noActivityTrigger)")
        if (self.deviceConnected) {
            print ("Watchdog deviceConnected")
            if (self.deviceAccessed){
            self.noActivityTrigger = 0
        } else {
            self.noActivityTrigger = self.noActivityTrigger + 1
            }
            
            // Clear deviceAccessed flag
            self.deviceAccessed = false
            // Evaluate if the app should disconnect from the peripherals since there
            if (self.noActivityTrigger) >= 7 {
                self.noActivityDisconnect = true
                self.centralManager.stopScan()
                print("stopScan")
                print ("Disconnect from all peripherals")
                for device in self.SBLightDimmerConnectedPeripherals {
                    self.centralManager.cancelPeripheralConnection(device)
                }
            }
        }
        self.watchdog()
        }
        
    }
    
    func closedown(){
            // Clear deviceAccessed flag
            self.deviceAccessed = false
            self.noActivityDisconnect = true
            self.centralManager.stopScan()
            print("stopScan")
            print ("Disconnect from all peripherals")
            for device in self.SBLightDimmerConnectedPeripherals {
                self.centralManager.cancelPeripheralConnection(device)
            }
    }
    
    
}
