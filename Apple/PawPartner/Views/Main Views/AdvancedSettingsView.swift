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
                Toggle("Show Note Dates", isOn: $showNoteDates)
                    .tint(.blue)
            } header: {
                Text("Show Note Dates")
            } footer: {
                Text("This displays the date a note was created ")
            }
            Section {
                TextField("https://example.com", text: $customFormURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Picker("Button Type", selection: $linkType) {
                    ForEach(linkTypes, id: \.self) {
                        Text($0)
                    }
                }
                Toggle(isCustomFormOn ? "Enabled" : "Disabled", isOn: $isCustomFormOn)
                    .tint(.blue)
            } header: {
                Text("Custom Animal Form")
            } footer: {
                Text("If you would like to prompt users to fill out a custom form of your choice after visiting with an animal, add the url and turn on the toggle. This will display a \"Custom Form\" button on the \"Thank You\" pop up after putting an animal back. If the button doesn't work, make sure your url begins with https://")
            }
        }
    }
}
