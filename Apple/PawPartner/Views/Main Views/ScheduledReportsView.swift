//
//  ScheduledReportsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 7/29/23.
//

import SwiftUI

struct ScheduledReportsView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Never"]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Label("Email", systemImage: "envelope.fill")
                    TextField("Email", text: $authViewModel.reportsEmail)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: authViewModel.reportsEmail) { newValue in
//                            print(newValue)
                            viewModel.updateScheduledReports(newDay: authViewModel.reportsDay, newEmail: newValue)
                        }
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Label("Day", systemImage: "calendar")
                    Picker("", selection: $authViewModel.reportsDay) {
                        ForEach(daysOfWeek, id: \.self) {
                            Text($0)
                        }
                    }
                    .labelsHidden()  // hide the blank label of the picker
                    .onChange(of: authViewModel.reportsDay) { newValue in
                        print(newValue)
                        viewModel.updateScheduledReports(newDay: newValue, newEmail: authViewModel.reportsEmail)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Scheduled Reports")
    }
}


struct ScheduledReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledReportsView()
    }
}
