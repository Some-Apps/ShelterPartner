import SwiftUI
import AlertToast

struct SettingsView: View {
    // MARK: -Properties
    @StateObject var viewModel = SettingsViewModel.shared
    
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var authenticationViewModel = AuthenticationViewModel()
    
    @AppStorage("sortBy") var sortBy: SortBy = .lastLetOut
    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("QRMode") var QRMode = true
    @AppStorage("volunteerVideo") var volunteerVideo: String = ""
    @AppStorage("staffVideo") var staffVideo: String = ""
    @AppStorage("guidedAccessVideo") var guidedAccessVideo: String = ""
    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("lastSync") var lastSync: String = ""


    @State private var showGuidedAccessVideo = false
    @State private var showLoading = false
    @State private var showStaffVideo = false
    @State private var showVolunteerVideo = false
    
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
    
    private var isVisitorBinding: Binding<Bool> {
            Binding<Bool>(
                get: { self.mode == "visitor" },
                set: { newValue in
                    self.mode = newValue ? "visitor" : "visitorAdmin"
                }
            )
        }
    
    private var isAdminBinding : Binding<Bool> {
            Binding<Bool>(
                get: { self.mode == "volunteerAdmin" },
                set: { newValue in
                    self.mode = newValue ? "volunteerAdmin" : "volunteer"
                }
            )
        }
    // MARK: -Body
    var body: some View {
            NavigationStack {
                Form {
                    Section(header: Text("General Settings")) {
//                        HStack {
//                            Image(systemName: "doc.richtext")
//                            Toggle("Visitor Mode", isOn: isVisitorBinding)
//                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
//                        }
//                        HStack {
//                            Image(systemName: "lock")
//                            Toggle("Volunteer Mode", isOn: isVolunteerBinding)
//                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
//                        }
                        HStack {
                            Image(systemName: "lock")
                            Toggle("Admin Mode", isOn: isAdminBinding)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        HStack {
                            Image(systemName: "qrcode")
                            Toggle("QR Codes", isOn: $QRMode)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }

                        Picker(selection: $sortBy) {
                            ForEach(SortBy.allCases, id: \.self) { sortOption in
                                Text(sortOption.rawValue).tag(sortOption)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "text.line.last.and.arrowtriangle.forward")
                                Text("Sort Options")
                            }
                        }
                        NavigationLink(destination: TagsView(species: .Cat)) {
                            HStack {
                                Image(systemName: "tag")
                                Text("Cat Tags")
                            }
                        }
                        NavigationLink(destination: TagsView(species: .Dog)) {
                            HStack {
                                Image(systemName: "tag")
                                Text("Dog Tags")
                            }
                        }
                        NavigationLink(destination: ScheduledReportsView()) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("Scheduled Reports")
                            }
                        }
                        NavigationLink(destination: AdvancedSettingsView()) {
                            HStack {
                                Image(systemName: "wrench.adjustable")
                                Text("Advanced Settings")
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
                        Button {
                            showVolunteerVideo = true
                        } label: {
                            HStack {
                                Image(systemName: "play.tv")
                                Text("Volunteer Walkthrough Video")
                            }
                        }
                        Button {
                            showStaffVideo = true
                        } label: {
                            HStack {
                                Image(systemName: "play.tv")
                                Text("Staff Walkthrough Video")
                            }
                        }
                        Button {
                            showGuidedAccessVideo = true
                            print(guidedAccessVideo)
                        } label: {
                            HStack {
                                Image(systemName: "play.tv")
                                Text("Guided Access Video")
                            }
                        }
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Version: \(appVersion)")
                        }
                    }
                }
                .navigationTitle("Settings")
                .onAppear {
                    viewModel.setupListener()
                }
            }
            .toast(isPresenting: $viewModel.showPasswordChanged) {
                AlertToast(type: .complete(.green), title: "Password Changed")
            }
            .toast(isPresenting: $showLoading) {
                AlertToast(displayMode: .hud, type: .loading)
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
        }
    // MARK: -Methods
    
    func handleSignOut() {
        animalViewModel.removeListeners()
        animalViewModel.cats = []
        animalViewModel.dogs = []
        authenticationViewModel.signOut()
        viewModel.reportsDay = "Never"
        viewModel.reportsEmail = ""
        storedSocietyID = ""
        lastSync = ""
        mode = "logIn"
    }
}

#Preview {
    SettingsView()
}
