//
//  HomeKitLockScreenWidget.swift
//  HomeKitLockScreenWidget
//
//  Created by Alexandre Yarmayan on 01/04/2025.
//

import WidgetKit
import SwiftUI

struct HomeKitLockScreenWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> HomeKitLockScreenWidgetEntry {
        HomeKitLockScreenWidgetEntry(date: Date(), temperature: 20.0, humidity: 50.0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HomeKitLockScreenWidgetEntry) -> Void) {
        let entry = HomeKitLockScreenWidgetEntry(date: Date(), temperature: 20.0, humidity: 50.0)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeKitLockScreenWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.com.votreSociete.HomeKitLockScreen")
        let temp = userDefaults?.double(forKey: "temperature") ?? 0.0
        let hum = userDefaults?.double(forKey: "humidity") ?? 0.0
        
        let entry = HomeKitLockScreenWidgetEntry(date: Date(), temperature: temp, humidity: hum)
        
        // Le widget se rafraîchira toutes les 15 minutes (à ajuster selon vos besoins)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct HomeKitLockScreenWidgetEntry: TimelineEntry {
    let date: Date
    let temperature: Double
    let humidity: Double
}

struct HomeKitLockScreenWidgetEntryView: View {
    var entry: HomeKitLockScreenWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Text("\(Int(entry.temperature))°C")
                        .font(.system(size: 12))
                    Text("\(Int(entry.humidity))%")
                        .font(.system(size: 12))
                }
            }
            
        case .accessoryRectangular:
            ZStack(alignment: .leading) {
                AccessoryWidgetBackground()
                HStack {
                    Text("T: \(Int(entry.temperature))°C | H: \(Int(entry.humidity))%")
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 6)
            }
            
        case .accessoryInline:
            Text("T: \(Int(entry.temperature))°C, H: \(Int(entry.humidity))%")
            
        default:
            Text("Format non géré")
        }
    }
}

@main
struct HomeKitLockScreenWidget: Widget {
    let kind: String = "HomeKitLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeKitLockScreenWidgetProvider()) { entry in
            HomeKitLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Widget Capteur HomeKit")
        .description("Affiche les mesures du capteur HomeKit sélectionné.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
