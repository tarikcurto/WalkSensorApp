//
//  BluetoothManager.swift
//  WalkSensor
//
//  Created by Tarik Curto on 11/11/23.
//

import Foundation
import CoreBluetooth
import SwiftUI

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral?
    var temperature: Binding<Float>?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if this is the device you're looking for
        print("Device scanned \(peripheral.name ?? "")")

        if peripheral.name == "picow_temp" {
            print("Device found")
            myPeripheral = peripheral
            myPeripheral?.delegate = self
            centralManager.stopScan()
            centralManager.connect(myPeripheral!)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "")")
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        for characteristic in service.characteristics! {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }

            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }

        if let data = characteristic.value {
            print("Raw data: \(data)")

            // Assuming the data is in little-endian format
            let intValue = data.withUnsafeBytes { $0.load(as: UInt16.self) }

            // Convert the UInt16 value to Float
            let _temperature = Float(intValue)/100

            print("Interpreted float value: \(_temperature)")

            DispatchQueue.main.async {
                self.temperature?.wrappedValue = _temperature
            }
        }
    }

}
