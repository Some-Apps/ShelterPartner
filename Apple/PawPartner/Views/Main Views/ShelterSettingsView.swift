//
//  DeviceSettingsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/7/24.
//

import SwiftUI

struct ShelterSettingsView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
        
    var body: some View {
        Form {
            Section {
                    NavigationLink(destination: AccountSetupView()) {
                        Button { } label: {
                            SettingElement(title: "Account Setup", explanation: "Change details about your shelter such as its name and current management software")
                                .foregroundStyle(.black)
                        }
                    }
                    NavigationLink(destination: VolunteerAccountsView()) {
                        Button { } label: {
                            SettingElement(title: "Volunteer Accounts", explanation: "Manage volunteer accounts and georestriction")
                                .foregroundStyle(.black)
                        }
                        }
                    
                
                    NavigationLink(destination: ScheduledReportsView()) {
                        Button { } label: {
                            SettingElement(title: "Scheduled Reports", explanation: "Receive a weekly email with details about activity in your shelter from the past week")
                                .foregroundStyle(.black)
                        }
                        }
                    
                
                NavigationLink(destination: TagsView(species: .Cat)) {
                    Button { } label: {
                        SettingElement(title: "Dog Tags", explanation: "Tags that users can add to cats")
                            .foregroundStyle(.black)
                    }
                }
                NavigationLink(destination: TagsView(species: .Dog)) {
                    Button { } label: {
                        SettingElement(title: "Dog Tags", explanation: "Tags that users can add to dogs")
                            .foregroundStyle(.black)
                    }
                }
                NavigationLink(destination: ReasonsForEarlyPutBackView()) {
                    Button { } label: {
                        SettingElement(title: "Early Reasons", explanation: "Reasons why an animal was put back before their minimum duration")
                            .foregroundStyle(.black)
                    }
                }
                NavigationLink(destination: LetOutTypesView()) {
                    Button { } label: {
                        SettingElement(title: "Let Out Types", explanation: "Different reasons for taking out an animal")
                            .foregroundStyle(.black)
                    }
                }
            }
        }
        .navigationTitle("Shelter Settings")
    }
}
