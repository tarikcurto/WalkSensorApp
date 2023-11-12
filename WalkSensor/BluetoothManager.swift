//
//  BluetoothManager.swift
//  WalkSensor
//
//  Created by Tarik Curto on 11/11/23.
//

import Foundation
import CoreBluetooth
import SwiftUI

extension Data {
    func toFloat(from offset: Int) -> Float? {
        guard self.count >= offset + 4 else { return nil }
        return self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Float.self) }
    }
}


class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral?
    var temperature: Binding<Float>?
    var temperatures: Binding<[Temperature]>?
    var accels: Binding<[Inertial]>?
    var gyros: Binding<[Inertial]>?
    var inertials: [Inertial] = Array(repeating: Inertial(Date.now, "x", 0), count: 6)
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // ble trigger
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available.")
        }
    }

    // scans for devices
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if this is the device you're looking for
        print("Device scanned: \(peripheral.name ?? "Unknown"), UUID: \(peripheral.identifier)")

        if peripheral.name == "inertial 1" {
            print("Device found")
            myPeripheral = peripheral
            myPeripheral?.delegate = self
            centralManager.stopScan()
            centralManager.connect(myPeripheral!)
        }
    }

    // connects to device
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "")")
        peripheral.discoverServices(nil)
    }

    // reads services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

        for service in peripheral.services! {
            print("Service discovered \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        //centralManager.cancelPeripheralConnection(peripheral)
    }

    // reads characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        for characteristic in service.characteristics! {
            print("Characteristic discovered \(characteristic.uuid) for service \(service.uuid)")
            if characteristic.properties.contains(.read) {
                print("Allow read!")
                peripheral.readValue(for: characteristic)
            }

            if characteristic.properties.contains(.notify) {
                print("Allow notify!")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    // reads values from characteristics
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }

        if let data = characteristic.value {
            print("Raw data: \(data), characteristic: \(characteristic.uuid), notification: \(characteristic.isNotifying)")

            if data.count == 0 {
                print("data count 0")
                return
            }
            
            if characteristic.uuid.isEqual(CBUUID(string: "2A6E")) {
                // Temperature
                print("Received temperature")
                let value = data.withUnsafeBytes { $0.load(as: UInt16.self) }
                let _temperature = Float(value)/100
                
                DispatchQueue.main.async {
                    self.temperature?.wrappedValue = _temperature
                    self.temperatures?.wrappedValue.append(Temperature(Date.now, _temperature))
                }
            }
            else if characteristic.uuid.isEqual(CBUUID(string: "00000001-0001-11EE-B962-0242AC120002")) {
                print("received accel")
                let accelx = data.toFloat(from: 0)!
                let accely = data.toFloat(from: 4)!
                let accelz = data.toFloat(from: 8)!
                let date = Date.now
                inertials[0] = Inertial(date, "x", accelx)
                inertials[1] = Inertial(date, "y", accely)
                inertials[2] = Inertial(date, "z", accelz)
            }
            else if characteristic.uuid.isEqual(CBUUID(string: "00000002-0001-11EE-B962-0242AC120002")) {
                print("received gyro")
                let gyrox = data.toFloat(from: 0)!
                let gyroy = data.toFloat(from: 4)!
                let gyroz = data.toFloat(from: 8)!
                let date = Date.now
                inertials[3] = Inertial(date, "x", gyrox)
                inertials[4] = Inertial(date, "y", gyroy)
                inertials[5] = Inertial(date, "z", gyroz)
                
                DispatchQueue.main.async {
                    let max = 300
                    let accelsc = (self.accels?.wrappedValue.count)!
                    if (accelsc > max) {
                        self.accels?.wrappedValue.removeFirst(accelsc - max)
                    }
                    let gyrosc = (self.gyros?.wrappedValue.count)!
                    if (gyrosc > max) {
                        self.gyros?.wrappedValue.removeFirst(gyrosc - max)
                    }
                    self.accels?.wrappedValue.append(contentsOf: self.inertials[0...2])
                    self.gyros?.wrappedValue.append(contentsOf: self.inertials[3...5])
                }
            }
            
        }
    }

}
