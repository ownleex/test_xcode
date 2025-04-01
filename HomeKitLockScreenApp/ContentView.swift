//
//  ContentView.swift
//  HomeKitLockScreenApp
//
//  Created by Alexandre Yarmayan on 01/04/2025.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    
    var body: some View {
        NavigationView {
            VStack {
                if let selected = homeKitManager.selectedSensor {
                    VStack(spacing: 10) {
                        Text("Capteur sélectionné : \(selected.name)")
                            .font(.headline)
                        if selected.hasTemperature {
                            Text("Température : \(homeKitManager.temperature ?? 0, specifier: "%.1f") °C")
                        }
                        if selected.hasHumidity {
                            Text("Humidité : \(homeKitManager.humidity ?? 0, specifier: "%.1f") %")
                        }
                        Button("Rafraîchir") {
                            homeKitManager.refreshSensorData()
                        }
                        .padding(.top, 5)
                    }
                    .padding()
                } else {
                    Text("Aucun capteur disponible.")
                }
                
                List(homeKitManager.availableSensors) { sensor in
                    HStack {
                        Text(sensor.name)
                        Spacer()
                        if sensor.id == homeKitManager.selectedSensor?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        homeKitManager.selectedSensor = sensor
                        homeKitManager.updateSensorValues()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Capteurs HomeKit")
        }
    }
}
