//
//  AdvancedSettingsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 1/15/24.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("minimumDuration") var minimumDuration = 5
    @AppStorage("customFormURL") var customFormURL = ""
    @AppStorage("isCustomFormOn") var isCustomFormOn = false
    @AppStorage("linkType") var linkType = "QR Code"
    @AppStorage("showNoteDates") var showNoteDates = true
    @AppStorage("requireName") var requireName = false
    @AppStorage("playgroupsEnabled") var playgroupsEnabled = false
    @ObservedObject var viewModel = SettingsViewModel.shared
    
    @AppStorage("filterPicker") var filterPicker: Bool = false
    
    let linkTypes = ["QR Code", "Open In App"]
    
    var body: some View {
        Form {
            Section {
                Stepper(minimumDuration == 1 ? "\(minimumDuration) minute" : "\(minimumDuration) minutes", value: $minimumDuration, in: 0...30, step: 1)
            } header: {
                Text("Minimum Log Duration")
            } footer: {
                Text("This sets the minimum duration for a visit. If a volunteer takes out an animal for a visit lasting less than this amount, it will show an error and not count the visit.")
            }
            Section {
                Toggle(playgroupsEnabled ? "Enabled" : "Disabled", isOn: $playgroupsEnabled)
                    .tint(.blue)
            } header: {
                Text("Playgroups")
            } footer: {
                Text("This feature is in testing. If you use playgroups in your shelter and would like to try this out, email jared@pawpartner.app.")
            }
            Section {
                Toggle("Show Note Dates", isOn: $showNoteDates)
                    .tint(.blue)
            } footer: {
                Text("This displays the date a note was created ")
            }
            Section {
                Toggle("Require Name", isOn: $requireName)
                    .tint(.blue)
            } footer: {
                Text("Before an animal can be taken out, you must enter your name.")
            }
            Section {
                Toggle("Filter Picker", isOn: $filterPicker)
                    .disabled(viewModel.filterOptions.isEmpty)
                    .tint(.blue)
                    .onAppear {
                        if viewModel.filterOptions.isEmpty {
                            filterPicker = false
                        }
                    }
            } footer: {
                Text(viewModel.filterOptions.isEmpty ? "Allow users to selected from additional filters on the main screen. As of now, this requires additional setup. Feel free to email jared@pawpartner.app if you're interested in using this feature." : "Allow users to filter animals from the main page.")
            }
            Section {
                Toggle(isCustomFormOn ? "Enabled" : "Disabled", isOn: $isCustomFormOn)
                    .tint(.blue)
                TextField("https://example.com", text: $customFormURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(!isCustomFormOn)
                    .foregroundStyle(isCustomFormOn ? .primary : .secondary)
                Picker("Button Type", selection: $linkType) {
                    ForEach(linkTypes, id: \.self) {
                        Text($0)
                    }
                }
                .disabled(!isCustomFormOn)
                .foregroundStyle(isCustomFormOn ? .primary : .secondary)
            } header: {
                Text("Custom Animal Form")
            } footer: {
                Text("If you would like to prompt users to fill out a custom form of your choice after visiting with an animal, add the url and turn on the toggle. This will display a \"Custom Form\" button on the \"Thank You\" pop up after putting an animal back. If the button doesn't work, make sure your url begins with https://")
            }
        }
    }
}
