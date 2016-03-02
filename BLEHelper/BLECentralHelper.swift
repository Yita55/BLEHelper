//
//  BLECentralHelper.swift
//  BLEHelper
//
//  Created by HarveyHu on 2/27/16.
//  Copyright © 2016 HarveyHu. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BLECentralHelperDelegate {
    func bleDidDisconenctFromPeripheral()
    func bleCentralDidReceiveData(data: NSData?, peripheral: CBPeripheral,characteristic: CBCharacteristic)
}

public class BLECentralHelper {
    public var delegate: BLECentralHelperDelegate?
    let centralManager: BLECentralManager
    var peripheralList: [CBPeripheral] = [CBPeripheral] ()
    var peripheral: CBPeripheral?
    var timer: NSTimer?
    
    public init() {
        // Set centralManager
        let bleCentralQueue: dispatch_queue_t = dispatch_queue_create("forBLECentralManagerOnly", DISPATCH_QUEUE_SERIAL)
        centralManager = BLECentralManager(queue: bleCentralQueue)
        centralManager.didReceiveDataHandler = {[weak self] (data: NSData?, peripheral: CBPeripheral ,characteristic: CBCharacteristic) -> (Void) in
            self?.delegate?.bleCentralDidReceiveData(data ,peripheral: peripheral, characteristic: characteristic)
        }
        centralManager.didDisconnectPeripheralCompletion = {[weak self] (peripheral, error) -> (Void) in
            self?.delegate?.bleDidDisconenctFromPeripheral()
        }
    }
    
    deinit {
        self.delegate = nil
        self.peripheral = nil
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func scanTimeout() {
        prettyLog("Scan Timeout")
        self.centralManager.stopScan()
    }
    
    //MARK - BLE Scanning
    public func scan(seconds: Double, serviceUUID: String?, handler:((devices: [CBPeripheral]) -> (Void))?) {
        prettyLog()
        self.timer?.invalidate()
        centralManager.stopScan()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: Selector("scanTimeout"), userInfo: nil, repeats: false)
        
        centralManager.scanWithServiceUUID(serviceUUID) {[weak self] (peripheral, advertisementData, RSSI) -> (Void) in
            
            if self?.peripheralList.filter({$0 == peripheral}).count > 0 {
                self?.peripheralList.append(peripheral)
            }
        }
    }
    
    //MARK - BLE Connecting
    public func connect(deviceUUID deviceUUIDString: String, completion: ((peripheral: CBPeripheral, error: NSError?) -> (Void))?) {
        prettyLog()
        if let deviceUUID = NSUUID.init(UUIDString: deviceUUIDString) {
            centralManager.connectPeripheralByDeviceUUID(deviceUUID, completion: completion)
        } else {
            prettyLog("deviceUUID is wrong")
        }
    }
    
    public func disconnect() {
        prettyLog()
        if let p = self.peripheral {
            centralManager.disconnect(p)
            self.peripheralList.removeAll()
        }
    }
    
    //get DeviceUUID
    public func getDeviceUUID() -> String? {
        return peripheral?.identifier.UUIDString
    }
    
    //MARK: - BLE Operation
    //read
    public func readValue(serviceUUID: String, characteristicUUID: String, response: (success: Bool)-> (Void)) {
        guard let peripheral = self.peripheral else {
            prettyLog("error: self.peripheral = nil")
            return
        }
        prettyLog()
        
        centralManager.fetchCharacteristic(peripheral, serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {[weak self] (characteristic) -> (Void) in
            if let p = self?.peripheral {
                self?.centralManager.readValueFromCharacteristic(p, characteristic: characteristic, completion: response)
            }
        }
    }
    
    //notify
    public func enableNotification(enable: Bool, serviceUUID: String, characteristicUUID: String, response:(success: Bool) -> (Void)) {
        guard let peripheral = self.peripheral else {
            prettyLog("error: self.peripheral = nil")
            return
        }
        prettyLog()
        
        centralManager.fetchCharacteristic(peripheral, serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {[weak self] (characteristic) -> (Void) in
            if let p = self?.peripheral {
                self?.centralManager.setNotificationState(p, turnOn: enable, characteristic: characteristic, response: response)
            }
        }
    }
    //write
    public func writeValue(data: NSData, serviceUUID: String, characteristicUUID: String, response:(success: Bool) -> (Void)) {
        guard let peripheral = self.peripheral else {
            prettyLog("error: self.peripheral = nil")
            return
        }
        prettyLog()
        
        centralManager.fetchCharacteristic(peripheral, serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {[weak self] (characteristic) -> (Void) in
            if let p = self?.peripheral {
                self?.centralManager.writeValueWithData(p, characteristic: characteristic, data: data, response: response)
            }
        }
    }
}

