//
//  ContentView.swift
//  WalkSensor
//
//  Created by Tarik Curto on 11/11/23.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var bluetoothManager = BluetoothManager()
    @State var temperature: Float = 0.0

    var body: some View {
        VStack {
            Text("Temperature \(temperature)")
                .onAppear {
                    bluetoothManager.temperature = $temperature
                }

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
