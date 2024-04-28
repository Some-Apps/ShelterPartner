//
//  PasswordPromptView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/28/23.
//

import AlertToast
import SwiftUI

struct PasswordPromptView: View {
    @Binding var isShowing: Bool
    @Binding var passwordInput: String
    @Binding var showIncorrectPassword: Bool
    let onSubmit: () -> Void

    @FocusState private var isPasswordFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Password")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            SecureField("Password", text: $passwordInput)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isPasswordFieldFocused)
            Button("Submit") {
                onSubmit()
                isShowing = false
            }
            .font(.title3)
            .buttonStyle(.bordered)
            .tint(.blue)
            Spacer()
        }
        .padding([.leading, .trailing, .bottom])
        .onAppear {
            isPasswordFieldFocused = true
        }
    }
}


struct PasswordPromptView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordPromptView(isShowing: .constant(true), passwordInput: .constant(""), showIncorrectPassword: .constant(false), onSubmit: {})
    }
}
