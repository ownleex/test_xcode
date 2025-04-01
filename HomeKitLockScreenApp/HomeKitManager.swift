//
//  HomeKitManager.swift
//  HomeKitLockScreenApp
//
//  Created by Alexandre Yarmayan on 01/04/2025.
//

import Foundation
import HomeKit
import WidgetKit

// Structure représentant un capteur avec ses caractéristiques
struct SensorInfo: Identifiable {
    let id: UUID      // Utilise accessory.uniqueIdentifier
    let name: String
    let hasTemperature: Bool
    let hasHumidity: Bool
}

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    @Published var availableSensors: [SensorInfo] = []
    @Published var selectedSensor: SensorInfo? {
        didSet {
            // Sauvegarde de l’identifiant du capteur sélectionné dans l’App Group
            if let sensor = selectedSensor {
                UserDefaults(suiteName: "group.com.mon_id.homekit")?
                    .set(sensor.id.uuidString, forKey: "selectedSensorID")
            }
        }
    }
    
    @Published var temperature: Double?
    @Published var humidity: Double?
    
    private var homeManager: HMHomeManager?
    
    override init() {
        super.init()
        self.homeManager = HMHomeManager()
        self.homeManager?.delegate = self
        
        // Lecture éventuelle du capteur précédemment sélectionné
        if let sensorIDString = UserDefaults(suiteName: "group.com.mon_id.homekit")?.string(forKey: "selectedSensorID"),
           let sensorUUID = UUID(uuidString: sensorIDString) {
            print("Capteur précédemment sélectionné : \(sensorUUID)")
            // La sélection sera rétablie lors de la mise à jour des capteurs dans homeManagerDidUpdateHomes
        }
    }
    
    // Cette méthode est appelée lorsque HomeKit a mis à jour la liste des maisons/accessoires
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        guard let home = manager.primaryHome else { return }
        
        var sensors: [SensorInfo] = []
        for accessory in home.accessories {
            var hasTemperature = false
            var hasHumidity = false
            for service in accessory.services {
                if service.serviceType == HMServiceTypeTemperatureSensor {
                    hasTemperature = true
                }
                if service.serviceType == HMServiceTypeHumiditySensor {
                    hasHumidity = true
                }
            }
            // Considère l’accessoire comme un capteur s’il fournit au moins une mesure
            if hasTemperature || hasHumidity {
                let sensor = SensorInfo(id: accessory.uniqueIdentifier,
                                        name: accessory.name,
                                        hasTemperature: hasTemperature,
                                        hasHumidity: hasHumidity)
                sensors.append(sensor)
            }
        }
        
        DispatchQueue.main.async {
            self.availableSensors = sensors
            
            // Tente de rétablir la sélection précédente
            if self.selectedSensor == nil,
               let sensorIDString = UserDefaults(suiteName: "group.com.mon_id.homekit")?.string(forKey: "selectedSensorID"),
               let sensorUUID = UUID(uuidString: sensorIDString),
               let sensor = sensors.first(where: { $0.id == sensorUUID }) {
                self.selectedSensor = sensor
            }
            
            // Sinon, sélectionne le premier capteur disponible par défaut
            if self.selectedSensor == nil, let firstSensor = sensors.first {
                self.selectedSensor = firstSensor
            }
            
            // Mise à jour des mesures pour le capteur sélectionné
            self.updateSensorValues()
        }
    }
    
    // Lit les mesures du capteur sélectionné et enregistre les valeurs dans l’App Group
    func updateSensorValues() {
        guard let home = homeManager?.primaryHome,
              let selectedSensor = selectedSensor else {
            return
        }
        
        // Recherche de l’accessoire correspondant au capteur sélectionné
        guard let accessory = home.accessories.first(where: { $0.uniqueIdentifier == selectedSensor.id }) else {
            return
        }
        
        for service in accessory.services {
            if selectedSensor.hasTemperature && service.serviceType == HMServiceTypeTemperatureSensor,
               let tempCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) {
                tempCharacteristic.readValue { [weak self] error in
                    if let error = error {
                        print("Erreur de lecture de la température : \(error)")
                    } else if let value = tempCharacteristic.value as? Double {
                        DispatchQueue.main.async {
                            self?.temperature = value
                            UserDefaults(suiteName: "group.com.mon_id.homekit")?
                                .set(value, forKey: "temperature")
                        }
                    }
                }
            }
            
            if selectedSensor.hasHumidity && service.serviceType == HMServiceTypeHumiditySensor,
               let humidityCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity }) {
                humidityCharacteristic.readValue { [weak self] error in
                    if let error = error {
                        print("Erreur de lecture de l'humidité : \(error)")
                    } else if let value = humidityCharacteristic.value as? Double {
                        DispatchQueue.main.async {
                            self?.humidity = value
                            UserDefaults(suiteName: "group.com.mon_id.homekit")?
                                .set(value, forKey: "humidity")
                        }
                    }
                }
            }
        }
    }
    
    // Méthode pour rafraîchir manuellement les données et forcer la mise à jour du widget
    func refreshSensorData() {
        updateSensorValues()
        WidgetCenter.shared.reloadTimelines(ofKind: "HomeKitLockScreenWidget")
    }
}
