//
//  SetupView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/3/24.
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    
    @AppStorage("filterPicker") var filterPicker: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Filter Picker", isOn: $filterPicker)
                    .disabled(viewModel.filterOptions.isEmpty)
                    .tint(.blue)
            } header: {
                Text("Filter Picker")
            } footer: {
                Text(viewModel.filterOptions.isEmpty ? "Allow users to filter animals from the main page. As of now, this requires additional setup. Feel free to email jared@pawpartner.app if you're interested in using this feature." : "Allow users to filter animals from the main page.")
            }
        }
    }
}

#Preview {
    SetupView()
}
