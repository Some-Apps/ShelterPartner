//
//  DeviceSettingsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/7/24.
//

import SwiftUI

struct AccountSettingsView: View {
    var body: some View {
        Form {
            NavigationLink(destination: EmptyView()) {
                HStack {
                    Text("Reasons For Early Put Back")
                    Image("questionmark.circle")
                }
            }
        }
    }
}
