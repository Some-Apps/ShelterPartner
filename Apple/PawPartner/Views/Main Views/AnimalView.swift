import SSToastMessage
import FirebaseAuth
import AlertToast
import SwiftUI
import Kingfisher
import WebKit
import UIKit

struct AnimalView: View {
    // MARK: -Properties
    @StateObject var cardViewModel = CardViewModel()
    @AppStorage("minimumDuration") var minimumDuration = 5

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @ObservedObject var viewModel = AnimalViewModel.shared
    @ObservedObject var settingsViewModel = SettingsViewModel.shared

    @AppStorage("filterPicker") var filterPicker: Bool = false
    @AppStorage("filter") var filter: String = "No Filter"
    @AppStorage("lastSync") var lastSync: String = ""
    @AppStorage("lastCatSync") var lastCatSync: String = ""
    @AppStorage("lastDogSync") var lastDogSync: String = ""
    @AppStorage("latestVersion") var latestVersion: String = ""
    @AppStorage("updateAppURL") var updateAppURL: String = ""
    @AppStorage("feedbackURL") var feedbackURL: String = ""
    @AppStorage("reportProblemURL") var reportProblemURL: String = ""
    @AppStorage("animalType") var animalType = AnimalType.Cat
    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("volunteerVideo") var volunteerVideo: String = ""
    @AppStorage("donationURL") var donationURL: String = ""
    @AppStorage("playgroupsFullyEnabled") var playgroupsFullyEnabled = false
    @AppStorage("playgroupsEnabled") var playgroupsEnabled = false


    @State private var showAnimalAlert = false
    @State private var screenWidth: CGFloat = 500
    @State private var isImageLoaded = false
    @State private var shouldPresentAnimalAlert = false
    @State private var shouldPresentThankYouView = false
    @State private var showingFeedbackForm = false
    @State private var showingReportForm = false
    @State private var showTutorialQRCode = false
    @State private var showingPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var showIncorrectPassword = false
    @State private var showDonateQRCode = false

    @FocusState private var focusField: Bool


    let columns = [
        GridItem(.adaptive(minimum: 330))
    ]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
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
    // MARK: -Body
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        showingFeedbackForm = true
                    } label: {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                            Text("Give Feedback")
                        }
                    }
                    .sheet(isPresented: $showingFeedbackForm) {
                        if let feedbackURL = URL(string: "\(feedbackURL)/?societyid=\(storedSocietyID)") {
                            WebView(url: feedbackURL)
                        }
                    }
                    Spacer()
                    if mode != "volunteerAdmin" && mode != "visitorAdmin" {
                        Button("Switch To Admin") {
                            showingPasswordPrompt = true
                        }
                        .sheet(isPresented: $showingPasswordPrompt) {
                            PasswordPromptView(isShowing: $showingPasswordPrompt, passwordInput: $passwordInput, showIncorrectPassword: $showIncorrectPassword) {
                                authViewModel.verifyPassword(password: passwordInput) { isCorrect in
                                    if isCorrect {
                                        // The password is correct. Enable the feature here.
                                        //                                        volunteerMode.toggle()
                                        mode = "volunteerAdmin"
                                        mode = "volunteerAdmin"
                                    } else {
                                        // The password is incorrect. Show an error message.
                                        print("Incorrect Password")
                                        showIncorrectPassword.toggle()
                                        passwordInput = ""
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                    }
                    if mode == "volunteerAdmin" || mode == "visitorAdmin" {
                        Button("Turn Off Admin") {
                            mode = "volunteer"
                        }
                        Spacer()
                    }
                   
                        Button("Switch To Visitor") {
                            if mode == "volunteerAdmin" {
                                mode = "visitorAdmin"
                            } else {
                                mode = "visitor"

                            }
                        }
                        Spacer()
                   
                    
                    Button {
                        showingReportForm = true
                    } label: {
                        HStack {
                            Text("Report Problem")
                            Image(systemName: "exclamationmark.bubble.fill")
                        }
                    }
                    .sheet(isPresented: $showingReportForm) {
                        if let reportProblemURL = URL(string: "\(reportProblemURL)/?societyid=\(storedSocietyID)") {
                            WebView(url: reportProblemURL)
                            
                        }
                    }
                }
                .padding([.horizontal, .top])
                .font(UIDevice.current.userInterfaceIdiom == .phone ? .caption : .body)

                if playgroupsEnabled || filterPicker {
                    CollapsibleSection()
                }
                
                
                Picker("Animal Type", selection: $animalType) {
                    Text("Cats").tag(AnimalType.Cat)
                    Text("Dogs").tag(AnimalType.Dog)
                }

                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])
                    .onChange(of: animalType) { newValue in
                        print("Animal type changed to: \(newValue)")
                        UserDefaults.standard.set(newValue.rawValue, forKey: "animalType")
                    }

                
                ScrollView {
                    switch animalType {
                        case .Dog:
                        if !playgroupsFullyEnabled {
                            AnimalGridView(
                                animals: viewModel.sortedDogs,
                                columns: columns,
                                cardViewModel: cardViewModel,
                                playCheck: filterPicker == true && filter != "No Filter" ? { $0.canPlay &&  (($0.filters != nil) ? $0.filters!.contains(filter) : false) } : { $0.canPlay },
                                cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                            )
                        } else {
                            PlaygroupAnimalGridView(
                                animals: viewModel.sortedDogs,
                                columns: columns,
                                cardViewModel: cardViewModel,
                                playCheck: filterPicker == true && filter != "No Filter" ? { $0.canPlay &&  (($0.filters != nil) ? $0.filters!.contains(filter) : false) } : { $0.canPlay },
                                cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                            )
                        }
                            

                        case .Cat:
                        if !playgroupsFullyEnabled {
                            AnimalGridView(
                                animals: viewModel.sortedCats,
                                columns: columns,
                                cardViewModel: cardViewModel,
                                playCheck: filterPicker == true && filter != "No Filter" ? { $0.canPlay &&  (($0.filters != nil) ? $0.filters!.contains(filter) : false) } : { $0.canPlay },
                                cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                            )
                        } else {
                            PlaygroupAnimalGridView(
                                animals: viewModel.sortedCats,
                                columns: columns,
                                cardViewModel: cardViewModel,
                                playCheck: filterPicker == true && filter != "No Filter" ? { $0.canPlay &&  (($0.filters != nil) ? $0.filters!.contains(filter) : false) } : { $0.canPlay },
                                cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                            )
                        }
                            
                        }

                    
                    Button {
                        showTutorialQRCode = true
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("Volunteer Tutorial Video")
                        }
                        .padding()
                        .fontWeight(.black)
                    }
                    
                    
                    switch animalType {
                    case .Cat:
                        Text("Last Cat Sync: \(lastCatSync)")
                            .foregroundStyle(Color.secondary)
                    case .Dog:
                        Text("Last Dog Sync: \(lastDogSync)")
                            .foregroundStyle(Color.secondary)
                    }
                    HStack {
                        if latestVersion != "\(appVersion)" {
                            VStack {
                                Text("Your app is not up to date. Please update when convenient.")
                                Button(action: {
                                    if let url = URL(string: updateAppURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {                                    
                                    Label("Update", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
                            .background(RoundedRectangle(cornerRadius: 20).fill(.customOrange))
                        }
                        VStack {
                            Text("PawPartner is completely free. You can follow us for free on Patreon to get behind-the-scenes updates.")
                            Button {
                                showDonateQRCode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                    showDonateQRCode = false
                                }
                            } label: {
                                Label("Patreon", systemImage: "qrcode")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
                        .background(RoundedRectangle(cornerRadius: 20).fill(.customBlue))
                    }
                    .padding([.bottom, .horizontal])
                }
            }
            // MARK: -Animal Alert
            .overlay(
                AnimalAlertView(animal: viewModel.animal)
                    .opacity(viewModel.showAnimalAlert ? 1 : 0)
            )
        }
        .onChange(of: lastSync) { sync in
            let cache = KingfisherManager.shared.cache
            try? cache.diskStorage.removeAll()
            cache.memoryStorage.removeAll()
            print("Cache removed")
        }
        .onChange(of: viewModel.showLogCreated) { newValue in
            if newValue {
                self.shouldPresentThankYouView = true
            } else {
                self.isImageLoaded = false
                self.shouldPresentThankYouView = false
            }
        }
        .onChange(of: isImageLoaded) { _ in
            updatePresentationState()
        }
        .onChange(of: viewModel.showAddNote) { _ in
            print(viewModel.showAddNote)
        }
        .onAppear {
            if settingsViewModel.filterOptions.isEmpty {
                filterPicker = false
            }
            if storedSocietyID == "" && Auth.auth().currentUser?.uid != nil {
                viewModel.fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
                    switch result {
                    case .success(let id):
                        storedSocietyID = id
                        viewModel.listenForSocietyLastSyncUpdate(societyID: id)
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            viewModel.fetchCatData()
            viewModel.fetchDogData()
            viewModel.fetchLatestVersion()
            if storedSocietyID.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                viewModel.postAppVersion(societyID: storedSocietyID, installedVersion: "\(appVersion) (\(buildNumber))")
            }
        }
        .present(isPresented: $shouldPresentThankYouView, type: .alert, animation: .easeIn(duration: 0.2), autohideDuration: 60, closeOnTap: false) {
                ThankYouView(animal: viewModel.animal)
        }
//        .present(isPresented: $viewModel.showLogTooShort) {
//            
//        }
//        .confirmationDialog("HMMM", isPresented: $viewModel.showLogTooShort) {
//            Text("Are you sure")
//        }
//        .toast(isPresenting: $viewModel.showLogTooShort, duration: 3) {
//            AlertToast(type: .error(.red), title: minimumDuration == 1 ? "Log must be at least \(minimumDuration) minute" : "Log must be at least \(minimumDuration) minutes")
//        }
        .toast(isPresenting: $showIncorrectPassword) {
            AlertToast(type: .error(.red), title: "Incorrect Password")
        }
        .toast(isPresenting: $viewModel.toastAddNote) {
            AlertToast(type: .complete(.green), title: "Note added!")
        }
        .sheet(isPresented: $viewModel.showQRCode) {
            QRCodeView(animal: viewModel.animal)
        }
        .sheet(isPresented: $showDonateQRCode) {
            CustomQRCodeView(url: donationURL)
        }
        .sheet(isPresented: $showTutorialQRCode) {
            Image(uiImage: generateQRCode(from: "https://www.youtube.com/watch?v=\(volunteerVideo)"))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 500)
        }
        .present(isPresented: $viewModel.showRequireName, type: .alert, autohideDuration: 60, closeOnTap: false, closeOnTapOutside: false) {
            RequireNameView(animal: viewModel.animal)
        }
        .sheet(isPresented: $viewModel.showAddNote) {
            AddNoteView(animal: viewModel.animal)
        }
    }
    // MARK: -Methods
    private func updatePresentationState() {
            shouldPresentThankYouView = viewModel.showLogCreated && isImageLoaded
        }
    
    
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

//#Preview {
//    AnimalView(cardViewModel: CardViewModel(), authViewModel: AuthenticationViewModel(), viewModel: AnimalViewModel(), lastSync: "", latestVersion: "1.0.0", updateAppURL: "google.com", animalType: AnimalType.Cat, storedSocietyID: "abc", volunteerMode: true)
//}


struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct AnimalGridView<Animal>: View where Animal: Identifiable {
    let animals: [Animal]
    let columns: [GridItem]
    let cardViewModel: CardViewModel
    let playCheck: (Animal) -> Bool
    let cardView: (Animal) -> CardView

    var body: some View {
        if animals.isEmpty {
            VStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: columns) {
                ForEach(animals, id: \.id) { animal in
                    if playCheck(animal) {
                        cardView(animal)
                            .padding(2)
                    }
                }
            }
            .padding()
        }
    }
}


struct PlaygroupAnimalGridView: View {
    let animals: [Animal]
    let columns: [GridItem]
    let cardViewModel: CardViewModel
    let playCheck: (Animal) -> Bool
    let cardView: (Animal) -> CardView
    
    var body: some View {
        if animals.isEmpty {
            VStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(groupAnimalsByPlaygroup().sorted(by: { (lhs, rhs) in
                        switch (lhs.key, rhs.key) {
                        case (nil, _):
                            return false
                        case (_, nil):
                            return true
                        default:
                            return lhs.key! < rhs.key!
                        }
                    }), id: \.key) { playgroup, animals in
                        Section(
                            header: NavigationLink {
                                PlaygroupsView(title: playgroup ?? "No Playgroup", animals: animals, columns: columns, cardViewModel: cardViewModel, playcheck: playCheck, cardView: cardView)
                            } label: {
                                HStack {
                                    Text(playgroup ?? "No Playgroup")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.title)
                                .bold()
                                .foregroundStyle(.black)
                                .padding(.top)
                                .padding([.leading, .trailing, .top])
                            }
                        ){
                            LazyVGrid(columns: columns) {
                                ForEach(animals, id: \.id) { animal in
                                    if playCheck(animal) {
                                        cardView(animal)
                                            .padding(2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
    
    private func groupAnimalsByPlaygroup() -> [String?: [Animal]] {
        Dictionary(grouping: animals, by: { $0.playgroup })
    }
}


struct CollapsibleSection: View {
    @State private var isExpanded: Bool = false
    
    @AppStorage("playgroupsEnabled") var playgroupsEnabled = false
    @AppStorage("playgroupsFullyEnabled") var playgroupsFullyEnabled = false
    @AppStorage("filterPicker") var filterPicker: Bool = false
    @AppStorage("filter") var filter: String = "No Filter"

    @ObservedObject var settingsViewModel = SettingsViewModel.shared
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Volunteer Mode Settings")
                        .font(.headline)
                        .foregroundStyle(.black)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.right" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            if isExpanded {
                VStack {
                    if playgroupsEnabled {
                        Toggle("Playgroups", isOn: $playgroupsFullyEnabled)
                            .tint(.blue)
                    }
                    if filterPicker {
                        Picker("Filter", selection: $filter) {
                            ForEach(settingsViewModel.filterOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding([.horizontal, .top])
    }
}
