//
//  HumaneSocietyApp.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/19/23.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Kingfisher


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}


@main
struct PawPartnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environment(\.sizeCategory, .medium)
        }
    }
}
