//
//  HomeKitLockScreenAppApp.swift
//  HomeKitLockScreenApp
//
//  Created by Alexandre Yarmayan on 01/04/2025.
//

import SwiftUI
import HomeKit

@main
struct HomeKitLockScreenApp: App {
    @StateObject private var homeKitManager = HomeKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(homeKitManager)
        }
    }
}
