//
//  ViewController.swift
//  blesample
//
//  Created by Thomas on 21/11/2019.
//  Copyright © 2019 Air France. All rights reserved.
//

import UIKit
import BleMesh

class ViewController: UIViewController, BleManagerDelegate {
    @IBOutlet weak var uiSessionID: UITextField!
    @IBOutlet weak var uiDeviceID: UITextField!
    @IBOutlet weak var uiActionConnect: UIButton!
    @IBOutlet weak var uiBroadcastAction: UIButton!
    @IBOutlet weak var uiDevicesList: UITextView!
    @IBOutlet weak var uiMessagesList: UITextView!
    // BLE working vars
    var sessionId: UInt64 = 0
    var terminalId: BleTerminalId = 0
    var bleItems: [BleItem] = []
    var nextItemIndex: BleItemIndex = 0
    var itemDatas = [UInt32: Data]()
    // Displayed vars
    var peripherals = NSMutableArray()
    var messages = [UInt64: [UInt32: String]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: invalidate UI
    
    func invalidatePeripherals() {
        print("Controller->invalidatePeripherals()")
        DispatchQueue.main.async {
            self.uiDevicesList.text = ""
            self.peripherals.forEach({peripheral in
                self.uiDevicesList.text = self.uiDevicesList.text + "\(peripheral)\n"
            })
        }
    }
    
    func invalidateMessages() {
        print("Controller->invalidateMessages()")
        DispatchQueue.main.async {
            var print = ""
            for (_, messageFromTerminal) in self.messages {
                for (_, message) in messageFromTerminal {
                    print += "\(message)\n"
                }
            }
            self.uiMessagesList.text = print
        }
    }
    
    // MARK: Actions
    
    @IBAction func onConnectPress(_ sender: Any) {
        print("Controller->onConnectPress()")
        
        if let session = uiSessionID.text {
            sessionId = UInt64(session) ?? 1
        } else {
            sessionId = 1
        }
        if let terminal = uiDeviceID.text {
            terminalId = UInt64(terminal) ?? UInt64.random(in: 1...10000)
        } else {
            terminalId = UInt64.random(in: 1...10000)
        }
        
        print("-> BleManager.shared.start(session:\(sessionId) , terminal:\(terminalId))")
        BleManager.shared.delegate = self
        BleManager.shared.start(session: sessionId, terminal: terminalId)
        
        uiDeviceID.resignFirstResponder()
        uiSessionID.resignFirstResponder()
    }
    
    @IBAction func onBroadcastPress(_ sender: Any) {
        print("Controller->onBroadcastPress()")
        
        let itemData = "Device:\(terminalId) send message with index:\(nextItemIndex)".data(using: .utf8) ?? Data()
        let headerData = "Broadcast".data(using: .utf8) ?? Data()
        let item = BleItem(terminalId: terminalId, itemIndex: nextItemIndex, previousIndexes: nil, size: UInt32(itemData.count), headerData: headerData)
        
        itemDatas[nextItemIndex] = itemData
        nextItemIndex = nextItemIndex + 1
        
        BleManager.shared.broadcast(item: item)
    }
    
    // MARK: BleManagerDelegate
    
    func bleManagerItemSliceFor(terminalId: BleTerminalId, index: BleItemIndex, offset: UInt32, length: UInt32) -> Data? {
        print("BleManagerDelegate->bleManagerItemSliceFor(terminalId:\(terminalId), index:\(index), offset:\(offset), length:\(length))")
        guard let itemData = itemDatas[index] else {
            print("ERROR: item data is nil for index:\(index)")
            return nil
        }
        guard offset < itemData.count else {
            print("ERROR: offset:(\(offset)) < itemData.count:(\(itemData.count))")
            return nil
        }
        return itemData[offset..<min(UInt32(itemData.count), UInt32(offset + length))]
    }
    
    func bleManagerDidReceive(item: BleItem, data: Data) {
        print("BleManagerDelegate->bleManagerDidReceive()")
        
        var messagesFromTerminal = messages[item.terminalId]
        if messagesFromTerminal == nil {
            messagesFromTerminal = [UInt32: String]()
            self.messages[item.terminalId] = messagesFromTerminal
        }
        
        self.messages[item.terminalId]?[item.itemIndex] = String(data:data, encoding: .utf8) ?? "ERROR"
        
        invalidateMessages()
    }
    
    func bleManagerDidConnect(peripheral peripheralIdentifier: String) {
        print("BleManagerDelegate->bleManagerDidConnect(peripheral:\(peripheralIdentifier))")
        peripherals.add(peripheralIdentifier)
        invalidatePeripherals()
    }
    
    func bleManagerDidDisconnect(peripheral peripheralIdentifier: String) {
        print("BleManagerDelegate->bleManagerDidDisconnect(peripheral:\(peripheralIdentifier))")
        peripherals.remove(peripheralIdentifier)
        invalidatePeripherals()
    }
    
    func bleManagerDidUpdateBluetoothState(_ state: BleManagerBluetoothState) {
        print("BleManagerDelegate->bleManagerDidUpdateBluetoothState()")
    }
    
    func bleManagerDidResolveIdentifier(terminal: BleTerminalId, peripheralIdentifier: String) {
        print("BleManagerDelegate->bleManagerDidResolveIdentifier()")
    }
    
    func bleManagerIsReceiving(item: BleItem, totalSizeReceived: UInt32) {
        print("BleManagerDelegate->bleManagerIsReceiving()")
    }

    func bleManagerIsSending(item: BleItem, totalSizeSent: UInt32) {
        print("BleManagerDelegate->bleManagerIsSending()")
    }
    
    func bleManagerDidStart() {
        print("BleManagerDelegate->bleManagerDidStart()")
    }
    
    func bleManagerDidStop() {
        print("BleManagerDelegate->bleManagerDidStop()")
    }
}

