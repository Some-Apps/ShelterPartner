import SwiftUI
import AlertToast
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit

struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
//    @Environment(\.isSearching) private var isSearching

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @StateObject var viewModel = SettingsViewModel.shared
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var authenticationViewModel = AuthenticationViewModel()

    @AppStorage("sortBy") var sortBy: SortBy = .lastLetOut
    @AppStorage("allowPhotoUploads") var allowPhotoUploads = true
    @AppStorage("volunteerVideo") var volunteerVideo: String = ""
    @AppStorage("staffVideo") var staffVideo: String = ""
    @AppStorage("guidedAccessVideo") var guidedAccessVideo: String = ""
    @AppStorage("lastSync") var lastSync: String = ""
    @AppStorage("updateAppURL") var updateAppURL: String = ""
    @AppStorage("latestVersion") var latestVersion: String = ""
    @AppStorage("adminMode") var adminMode = true

//    @State private var searchText = ""
    @State private var showGuidedAccessVideo = false
    @State private var showLoading = false
    @State private var showStaffVideo = false
    @State private var showVolunteerVideo = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var showIncorrectPassword = false

    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown Version"
    }

    var buildNumber: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown Build"
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                    Section(header: Text("Account Details")) {
                        if !authViewModel.name.isEmpty {
                            HStack {
                                Text("Name:")
                                    .bold()
                                Text(authViewModel.name)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !authViewModel.shelter.isEmpty {
                            HStack {
                                Text("Shelter:")
                                    .bold()
                                Text(authViewModel.shelter)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !authViewModel.shelterID.isEmpty {
                            HStack {
                                Text("Shelter ID:")
                                    .bold()
                                Text(authenticationViewModel.shelterID)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !authViewModel.software.isEmpty {
                            HStack {
                                Text("Management Software:")
                                    .bold()
                                Text(authViewModel.software)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !authViewModel.apiKey.isEmpty {
                            HStack {
                                Text("API Key:")
                                    .bold()
                                Text(authViewModel.apiKey)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !authViewModel.mainFilter.isEmpty {
                            HStack {
                                Text("Filter:")
                                    .bold()
                                Text(authViewModel.mainFilter)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                    }
                Section {
                    NavigationLink(destination: ShelterSettingsView()) {
                        HStack {
                            Image(systemName: "cloud")
                            Text("Shelter Settings")
                        }
                    }
                    NavigationLink(destination: DeviceSettingsView()) {
                        HStack {
                            Image(systemName: "ipad")
                            Text("Device Settings")
                        }
                        
                    }
                }
                    Section(header: Text("Account")) {
                            NavigationLink(destination: ChangePasswordView()) {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                    Text("Change Password")
                                }
                            }
                        
                            Button {
                                handleSignOut()
                            } label: {
                                HStack {
                                    Image(systemName: "door.left.hand.open")
                                    Text("Sign Out")
                                }
                                .foregroundStyle(.red)
                            }
                        
                    }
                

                    Section(header: Text("About")) {
                        Link("Tutorials", destination: URL(string: "https://shelterpartner.org/wiki")!)
                        
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Version: \(appVersion)")
                        }
                        .foregroundStyle(.secondary)
                        if latestVersion != appVersion {
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.red)
                                Text("Your app is not up to date. Please update when convenient.")
                                    .foregroundStyle(.red)
                                Link("Update", destination: (URL(string: updateAppURL) ?? URL(string: "https://shelterpartner.org"))!)
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                

                    Section {
                        HStack {
                            Image(systemName: "pawprint.fill")
                            Text("Dedicated to Aslan")
                        }
                        .foregroundStyle(.secondary)
                    }
                
            }
//            .searchable(text: $searchText)
            .navigationTitle("Settings")
            .onAppear {
                animalViewModel.fetchLatestVersion()
            }
        }
        .toast(isPresenting: $viewModel.showPasswordChanged) {
            AlertToast(type: .complete(.green), title: "Password Changed")
        }
        .toast(isPresenting: $viewModel.showAccountUpdated) {
            AlertToast(type: .complete(.green), title: "Account Updated")
        }
        .toast(isPresenting: $showLoading) {
            AlertToast(displayMode: .alert, type: .loading)
        }
        .sheet(isPresented: $showVolunteerVideo) {
            YoutubeVideoView(videoID: volunteerVideo)
        }
        .sheet(isPresented: $showStaffVideo) {
            YoutubeVideoView(videoID: staffVideo)
        }
        .sheet(isPresented: $showGuidedAccessVideo) {
            YoutubeVideoView(videoID: guidedAccessVideo)
        }
        .sheet(isPresented: Binding(
            get: { showShareSheet },
            set: { showShareSheet = $0 }
        )) {
            ActivityView(activityItems: shareItems)
        }
        .sheet(isPresented: $showingPasswordPrompt) {
            PasswordPromptView(isShowing: $showingPasswordPrompt, passwordInput: $passwordInput, showIncorrectPassword: $showIncorrectPassword) {
                authViewModel.verifyPassword(password: passwordInput) { isCorrect in
                    if isCorrect {

                    } else {
                        print("Incorrect Password")
                        showIncorrectPassword.toggle()
                        passwordInput = ""
                        dismiss()
                    }
                }
            }
        }
        .toast(isPresenting: $showIncorrectPassword) {
            AlertToast(type: .error(.red), title: "Incorrect Password")
        }
    }

    // MARK: - Methods

    func handleSignOut() {
        animalViewModel.removeListeners()
        animalViewModel.cats = []
        animalViewModel.dogs = []
        authenticationViewModel.signOut()
        authViewModel.reportsDay = "Never"
        authViewModel.reportsEmail = ""
        authenticationViewModel.shelterID = ""
        lastSync = ""
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}
