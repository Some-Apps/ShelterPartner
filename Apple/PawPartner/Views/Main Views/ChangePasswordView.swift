//
//  ChangePasswordView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/27/23.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settingsViewModel = SettingsViewModel.shared
    @ObservedObject var authenticationViewModel = AuthenticationViewModel.shared
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var newPasswordDuplicate = ""
    
    var disabled: Bool {
        if newPassword != newPasswordDuplicate || oldPassword.isEmpty || newPassword.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        Form {
            Section {
                SecureField("Old Password", text: $oldPassword)
            }
            Section {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $newPasswordDuplicate)
            }
            Section {
                Button("Change Password") {
                    authenticationViewModel.updatePassword(oldPassword: oldPassword, newPassword: newPassword)
                    dismiss()
                    settingsViewModel.showPasswordChanged.toggle()
                }.disabled(disabled)
            }
        }
        .navigationTitle("Change Password")
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
    }
}
