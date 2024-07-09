//
//  DeviceSettingsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/7/24.
//

import SwiftUI

struct AccountSettingsView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    
    @State private var popoverReasons = false
    
    var body: some View {
        Form {
            Section {
                    NavigationLink(destination: AccountSetupView()) {
                            Text("Account Setup")
                    }
                    NavigationLink(destination: VolunteerAccountsView()) {
                            Text("Volunteer Accounts")
                        }
                    
                
                    NavigationLink(destination: ScheduledReportsView()) {
                            Text("Scheduled Reports")
                        }
                    
                
                NavigationLink(destination: TagsView(species: .Cat)) {
                        Text("Cat Tags")
                }
                NavigationLink(destination: TagsView(species: .Dog)) {
                        Text("Dog Tags")
                }
                NavigationLink("Early Reasons", destination: ReasonsForEarlyPutBackView())
            } 
        }
        .navigationTitle("Account Settings")
    }
}
