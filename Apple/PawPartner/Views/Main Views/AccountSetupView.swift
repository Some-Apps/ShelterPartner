import AlertToast
import SwiftUI

struct AccountSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel = SettingsViewModel.shared

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
    @State private var showingPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var showIncorrectPassword = false
    
    @State private var shelterName = ""
    @State private var managementSoftware = ""
    
    let managementSoftwareOptions = ["", "ShelterLuv", "ShelterManager"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Shelter Name", text: $authViewModel.shelter)
                    Picker("Management Software", selection: $authViewModel.software) {
                        ForEach(managementSoftwareOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }
                Section {
//                    TextField("API Key", text: $viewModel.apiKey)
                    NavigationLink("Main Filter", destination: FilterView())
                }
                Section {
                    Button("Save") {
                        viewModel.updateAccountSettings(shelter: authViewModel.shelter, software: authViewModel.software, apiKey: authViewModel.apiKey, mainFilter: authViewModel.mainFilter)
                        dismiss()
                        viewModel.showAccountUpdated = true
                    }
                }
            }
        }

    }
}
