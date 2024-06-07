//
//  DeviceSettingsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/7/24.
//

import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel

    
    @State private var popoverReasons = false
    
    var body: some View {
        Form {
            Section {
                NavigationLink("\(viewModel.earlyReasons.count) reasons", destination: ReasonsForEarlyPutBackView().environmentObject(viewModel))
            } header: {
                HStack {
                    Text("Reasons for early put back")
                    Button {
                        popoverReasons = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $popoverReasons) {
                        Text("Set the reasons a volunteer can select from why they had to put an animal back.")
                            .padding()
                            .textCase(nil)
                    }
                }
            }
        }
    }
}
