//
//  ContentView.swift
//  WalkSensor
//
//  Created by Tarik Curto on 11/11/23.
//

import SwiftUI
import Charts

struct Temperature: Identifiable {
    var id: Date
    var c: Float


    init(_ date: Date, _ c: Float) {
        self.id = date
        self.c = c
    }
}

struct Inertial: Identifiable {
    var id: String
    var date: Date
    var cord: String
    var value: Float
    
    init(_ date: Date, _ cord: String, _ value: Float) {
        self.date = date
        self.cord = cord
        self.value = value
        self.id = "\(date)-\(cord)"
    }
}


struct ContentView: View {
    
    

    @ObservedObject var bluetoothManager = BluetoothManager()
    @State var temperature: Float = 0.0
    @State var temperatures: [Temperature] = []
    @State var accels: [Inertial] = []
    @State var gyros: [Inertial] = []

    var body: some View {
        
        
        VStack {
            
            /*Chart(temperatures) {
                LineMark (
                    x: .value("Ts", $0.id),
                    y: .value("Temperature", $0.c)
                )
            }
            .onAppear {
                bluetoothManager.temperatures = $temperatures
            }*/
            
            Text("Accel")
            Chart(accels) {
                LineMark (
                    x: .value("Ts", $0.id),
                    y: .value("Value", $0.value)
                )
                .foregroundStyle(by: .value("Coordinate", $0.cord))
            }
            
            Text("Gyro")
            Chart(gyros) {
                LineMark (
                    x: .value("Ts", $0.id),
                    y: .value("Value", $0.value)
                )
                .foregroundStyle(by: .value("Coordinate", $0.cord))
            }
            
            /*Button(action: action1) {
                Text("Click me!!!")
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.borderedProminent)*/
            
            HStack{
                Text("Temperature \(temperature)")
                Button("Clear") {
                    self.$accels.wrappedValue.removeAll()
                    self.$gyros.wrappedValue.removeAll()
                }
                .buttonStyle(.borderedProminent)
                
            }

        }
        .padding()
        .onAppear {
            bluetoothManager.temperature = $temperature
            bluetoothManager.temperatures = $temperatures
            
            bluetoothManager.accels = $accels
            bluetoothManager.gyros = $gyros
        }
    }
    
    func action1() {
        print("click!!!")
        bluetoothManager.myPeripheral?.discoverServices(nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
