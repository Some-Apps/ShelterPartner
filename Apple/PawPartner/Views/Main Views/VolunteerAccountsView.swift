//
//  VolunteerAccountsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/27/24.
//

import SwiftUI

struct VolunteerAccountsView: View {
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        Form {
            Section("Add Volunteer") {
                TextField("Volunteer Name", text: $name)
                TextField("Volunteer Email", text: $email)
                Button("Send Invite") {
                    
                }
            }
            Section("Volunteers") {
                
            }
            Section("Volunteer Settings") {
                Toggle("Geo-restrict Volunteer Accounts", isOn: .constant(true))
                    .tint(.blue)
            }
        }
    }
}

#Preview {
    VolunteerAccountsView()
}
