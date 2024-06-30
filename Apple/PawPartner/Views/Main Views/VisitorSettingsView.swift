//
//  VisitorSettingsView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 6/30/24.
//

import SwiftUI

struct VisitorSettingsView: View {
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
    var body: some View {
        Button("Sign Out") {
            authViewModel.signOut()
        }
    }
}

#Preview {
    VisitorSettingsView()
}
