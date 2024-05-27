import SwiftUI
import Combine
import FirebaseAuth
import AlertToast
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
    @AppStorage("showAllAnimals") var showAllAnimals = false

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
    @AppStorage("groupsFullyEnabled") var groupsFullyEnabled = false
    @AppStorage("groupsEnabled") var groupsEnabled = false

    @State private var filteredAnimalsList: [Animal] = []

    @State private var searchQuery = ""
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
    
    @State private var searchQueryFinished = ""
    @State private var selectedFilterAttribute = "Name"
    @State private var isSearching = false
    
    let filterAttributes = ["Name", "Breed", "Location", "Notes"]

    let columns = [
        GridItem(.adaptive(minimum: 350))
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

    // MARK: - Body
    var body: some View {
        NavigationStack {
                    ScrollView {
                        LazyVStack {
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
                                                    mode = "volunteerAdmin"
                                                } else {
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

                            if groupsEnabled || filterPicker {
                                CollapsibleSection()
                            }
                            
                            Picker("Animal Type", selection: $animalType) {
                                Text("Cats").tag(AnimalType.Cat)
                                Text("Dogs").tag(AnimalType.Dog)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding([.horizontal, .top])
                            .onChange(of: animalType) { newValue in
                                print("Animal type changed to: \(newValue)")
                                UserDefaults.standard.set(newValue.rawValue, forKey: "animalType")
//                                searchQuery = ""
//                                searchQueryFinished = ""
//                                filteredAnimalsList = animalType == .Cat ? viewModel.sortedCats : viewModel.sortedDogs
//                                updateFilteredAnimals()
                            }
//                            VStack(spacing: 20) {
//                                TextField("Search", text: $searchQuery)
//                                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                                    .padding(.horizontal)
//                                    .frame(maxWidth: UIScreen.main.bounds.width/2)
//                                    .font(.largeTitle)
//                                    .fontWeight(.black)
//                                HStack(spacing: 20) {
//                                    Picker("Filter by", selection: $selectedFilterAttribute) {
//                                        ForEach(filterAttributes, id: \.self) { attribute in
//                                            Text(attribute).tag(attribute)
//                                        }
//                                    }
//                                    .pickerStyle(MenuPickerStyle())
//
//                                    Button(action: {
//                                        isSearching = true
//                                        filteredAnimalsList = filteredAnimals()
//
//                                        isSearching = false
//                                        searchQueryFinished = searchQuery
//                                    }) {
//                                        Text("Search")
//                                            .buttonStyle(.bordered)
//
//                                    }
//                                    .padding(.horizontal)
//
//                                    Button(action: {
//                                        searchQuery = ""
//                                        searchQueryFinished = ""
//                                        filteredAnimalsList = animalType == .Cat ? viewModel.sortedCats : viewModel.sortedDogs
//                                    }) {
//                                        Text("Reset Search")
//                                            .buttonStyle(.bordered)
//                                    }
//                                    .padding(.horizontal)
//                                }
//
//                            }
//                            .padding(.top)
//                            if !searchQueryFinished.isEmpty {
//                                Text("Results for \(searchQueryFinished)")
//
//                            }
                            switch animalType {
                            case .Dog:
                                if !groupsFullyEnabled {
                                    AnimalGridView(
                                        animals: viewModel.sortedDogs,
                                        columns: columns,
                                        cardViewModel: cardViewModel,
                                        cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                                    )
                                } else {
                                    GroupAnimalGridView(
                                        animals: viewModel.sortedDogs,
                                        columns: columns,
                                        cardViewModel: cardViewModel,
                                        cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                                    )
                                }
                            case .Cat:
                                if !groupsFullyEnabled {
                                    AnimalGridView(
                                        animals: viewModel.sortedCats,
                                        columns: columns,
                                        cardViewModel: cardViewModel,
                                        cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                                    )
                                } else {
                                    GroupAnimalGridView(
                                        animals: viewModel.sortedCats,
                                        columns: columns,
                                        cardViewModel: cardViewModel,
                                        cardView: { CardView(animal: $0, showAnimalAlert: $showAnimalAlert, viewModel: cardViewModel) }
                                    )
                                }
                            }
                            
                            
                            
                            if animalType == .Cat ? (!viewModel.sortedCats.isEmpty) : (!viewModel.sortedDogs.isEmpty) {
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
                    }
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
        .onDisappear {
            viewModel.removeListeners()
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
            viewModel.fetchCatData { _ in }
            viewModel.fetchDogData { _ in }
            viewModel.fetchLatestVersion()
            if storedSocietyID.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                viewModel.postAppVersion(societyID: storedSocietyID, installedVersion: "\(appVersion) (\(buildNumber))")
            }
        }
        .present(isPresented: $shouldPresentThankYouView, type: .alert, animation: .easeIn(duration: 0.2), autohideDuration: 60, closeOnTap: false) {
            ThankYouView(animal: viewModel.animal)
        }
        .toast(isPresenting: $showIncorrectPassword) {
            AlertToast(type: .error(.red), title: "Incorrect Password")
        }
        .toast(isPresenting: $viewModel.toastAddNote) {
            AlertToast(type: .complete(.green), title: "Note added!")
        }
        .toast(isPresenting: $isSearching) {
            AlertToast(displayMode: .alert, type: .loading, title: "Searching")
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
    
//    private func loadData() {
//         if animalType == .Cat {
//             viewModel.fetchCatData { success in
//                 if success {
//                     self.filteredAnimalsList = viewModel.sortedCats.filter(playCheck)
//                     print("Loaded \(self.filteredAnimalsList.count) cats into view")
//                 } else {
//                     print("Failed to load cat data")
//                 }
//             }
//         } else {
//             viewModel.fetchDogData { success in
//                 if success {
//                     self.filteredAnimalsList = viewModel.sortedDogs.filter(playCheck)
//                     print("Loaded \(self.filteredAnimalsList.count) dogs into view")
//                 } else {
//                     print("Failed to load dog data")
//                 }
//             }
//         }
//     }

//     private func playCheck(animal: Animal) -> Bool {
//         var result = true
//         if !showAllAnimals {
//             let canPlay = animal.canPlay
//             result = canPlay
//             print("Animal \(animal.id) - canPlay: \(canPlay), result: \(result)")
//         }
//         return result
//     }
    
    private func updateFilteredAnimals() {
        filteredAnimalsList = animalType == .Cat ? viewModel.sortedCats : viewModel.sortedDogs
    }
    
    // MARK: - Methods
//    private func filteredAnimals() -> [Animal] {
//        let animals = animalType == .Cat ? viewModel.sortedCats : viewModel.sortedDogs
//        guard !searchQuery.isEmpty else { return animals.filter { $0.canPlay } }
//
//        let filtered = animals.filter { $0.canPlay }
//
//        switch selectedFilterAttribute {
//        case "Name":
//            return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
//        case "Breed":
//            return filtered.filter { $0.breed?.localizedCaseInsensitiveContains(searchQuery) ?? false }
//        case "Location":
//            return filtered.filter { $0.fullLocation?.localizedCaseInsensitiveContains(searchQuery) ?? false }
//        case "Notes":
//            return filtered.filter { $0.notes.description.localizedCaseInsensitiveContains(searchQuery) }
//        default:
//            return filtered
//        }
//    }

    
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
                        cardView(animal)
                            .padding(2)
                }
            }
            .padding()
//            .id(animals)  // Force UI update
        }
    }
}

struct GroupAnimalGridView: View {
    let animals: [Animal]
    let columns: [GridItem]
    let cardViewModel: CardViewModel
    let cardView: (Animal) -> CardView
    
    var body: some View {
        if animals.isEmpty {
            VStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(groupAnimals().sorted(by: { (lhs, rhs) in
                        switch (lhs.key, rhs.key) {
                        case (nil, _):
                            return false
                        case (_, nil):
                            return true
                        default:
                            return lhs.key! < rhs.key!
                        }
                    }), id: \.key) { group, animals in
                        Section(
                            header: NavigationLink {
                                GroupsView(title: group ?? "No Group", animals: animals, columns: columns, cardViewModel: cardViewModel, cardView: cardView)
                            } label: {
                                HStack {
                                    Text(group ?? "No Group")
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
                                        cardView(animal)
                                            .padding(2)
                                }
                            }
                            .padding(.horizontal)
                            .id(animals)  // Force UI update

                        }
                    }
                }
            }
        }
    }
    
    private func groupAnimals() -> [String?: [Animal]] {
        Dictionary(grouping: animals, by: { $0.group })
    }
}

struct CollapsibleSection: View {
    @State private var isExpanded: Bool = false
    
    @AppStorage("groupsEnabled") var groupsEnabled = false
    @AppStorage("groupsFullyEnabled") var groupsFullyEnabled = false
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
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            if isExpanded {
                if groupsEnabled {
                    Toggle("Groups", isOn: $groupsFullyEnabled)
                        .tint(.blue)
                }
//                if filterPicker {
//                    Picker("Filter", selection: $filter) {
//                        ForEach(settingsViewModel.filterOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(.navigationLink)
//                    .foregroundStyle(.black)
//                }
            }
        }
        .padding([.horizontal, .top])
    }
}
