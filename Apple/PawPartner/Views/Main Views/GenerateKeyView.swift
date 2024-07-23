import SwiftUI
import AlertToast

struct GenerateKeyView: View {
    @ObservedObject var viewModel = SettingsViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @State private var keyName = ""
    @State private var showAlert = false
    @State private var generatedKey: String? = nil
    @State private var showCopied = false

    var body: some View {
        Form {
            Section("Generate New Key") {
                TextField("Key Name", text: $keyName)
                
                if keyName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Button("Add Key") {
                        let randomKey = generateRandomString(length: 16)
                        viewModel.addKey(name: keyName, key: randomKey)
                        generatedKey = randomKey
                        showAlert = true
                        keyName = ""
                    }
                    .disabled(keyName.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                }
            }
            
            Section {
                Text("\(authViewModel.requestCount)/\(authViewModel.rateLimit) requests made in the last 30 days")
            }
            
            Section("Available Endpoints") {
                HStack {
                    Text("All Dogs")
                    Button {
                        UIPasteboard.general.string = "https://us-central1-humanesociety-21855.cloudfunctions.net/APIEndpoint?societyId=\(authViewModel.shelterID)&apiKey=YOUR-API-KEY-HERE&species=Dogs"
                        showCopied = true
                    } label: {
                        Text("Copy To Clipboard")
                    }
                }
                HStack {
                    Text("All Cats")
                    Button {
                        UIPasteboard.general.string = "https://us-central1-humanesociety-21855.cloudfunctions.net/APIEndpoint?societyId=\(authViewModel.shelterID)&apiKey=YOUR-API-KEY-HERE&species=Cats"
                        showCopied = true
                    } label: {
                        Text("Copy To Clipboard")
                    }
                }
            }
            
            Section("Keys") {
                ForEach(authViewModel.apiKeys) { key in
                    HStack {
                        Text(key.name)
                            .font(.title3)
                    }
                }
                .onDelete(perform: deleteKey)
            }
        }
        .navigationTitle("API Keys")
        .toolbar {
            EditButton()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("API Key Generated"),
                message: Text("Your new API key is \(generatedKey ?? ""). Please copy and store it safely. You won't be able to access it after dismissing this alert."),
                primaryButton: .default(Text("Copy")) {
                    if let key = generatedKey {
                        UIPasteboard.general.string = key
                        showCopied = true
                    }
                },
                secondaryButton: .cancel(Text("Dismiss"))
            )
        }
        .toast(isPresenting: $showCopied) {
            AlertToast(displayMode: .hud, type: .systemImage("square.on.square", .secondary), title: "Copied to clipboard")
        }
    }

    func deleteKey(at offsets: IndexSet) {
        offsets.forEach { index in
            let key = authViewModel.apiKeys[index]
            viewModel.deleteKey(key)
        }
    }

    func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}
