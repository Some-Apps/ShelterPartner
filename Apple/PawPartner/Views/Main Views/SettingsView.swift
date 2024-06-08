import SwiftUI
import AlertToast
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit

struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
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

    private var isVisitorBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.mode == "visitor" },
            set: { newValue in
                self.mode = newValue ? "visitor" : "visitorAdmin"
            }
        )
    }

    private var isAdminBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.mode == "volunteerAdmin" },
            set: { newValue in
                self.mode = newValue ? "volunteerAdmin" : "volunteer"
            }
        )
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                    Section(header: Text("Account Details")) {
                        if viewModel.shelter != "" {
                            HStack {
                                Text("Shelter:")
                                    .bold()
                                Text(viewModel.shelter)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if storedSocietyID != "" {
                            HStack {
                                Text("Shelter ID:")
                                    .bold()
                                Text(storedSocietyID)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if viewModel.software != "" {
                            HStack {
                                Text("Management Software:")
                                    .bold()
                                Text(viewModel.software)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if viewModel.apiKey != "" {
                            HStack {
                                Text("API Key:")
                                    .bold()
                                Text(viewModel.apiKey)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if viewModel.mainFilter != "" {
                            HStack {
                                Text("Filter:")
                                    .bold()
                                Text(viewModel.mainFilter)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                    }
                
                
                Section("Account Settings") {
                    NavigationLink(destination: AccountSetupView()) {
                        HStack {
                            Image(systemName: "shared.with.you")
                            Text("Account Setup")
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
                    NavigationLink(destination: AccountSettingsView()) {
                        HStack {
                            Image(systemName: "wrench.adjustable")
                            Text("More Account Settings")
                        }
                    }
                }

                Section("Device Settings") {
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
                    Button {
                        downloadAllData()
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Download All Data")
                        }
                    }
                    NavigationLink(destination: DeviceSettingsView()) {
                        HStack {
                            Image(systemName: "wrench.adjustable")
                            Text("More Device Settings")
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
                    .foregroundStyle(.secondary)
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
        viewModel.reportsDay = "Never"
        viewModel.reportsEmail = ""
        storedSocietyID = ""
        lastSync = ""
        mode = "logIn"
    }
    
    func downloadAllData() {
        showLoading = true
        
        let db = Firestore.firestore()
        let documentRef = db.collection("Societies").document(storedSocietyID)
        
        documentRef.getDocument { (document, error) in
            guard let document = document, document.exists else {
                print("Document does not exist")
                showLoading = false
                return
            }
            
            var csvString = "id,name,species,note,note date,note person,log start,log end,log person\n"
            
            // Fetch Cats
            documentRef.collection("Cats").getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting cat documents: \(error)")
                    showLoading = false
                    return
                }
                
                for document in querySnapshot!.documents {
                    let data = document.data()
                    if let animal = parseAnimal(data: data) {
                        csvString.append(contentsOf: formatAnimalToCSV(animal: animal))
                    }
                }
                
                // Fetch Dogs
                documentRef.collection("Dogs").getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting dog documents: \(error)")
                        showLoading = false
                        return
                    }
                    
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        if let animal = parseAnimal(data: data) {
                            csvString.append(contentsOf: formatAnimalToCSV(animal: animal))
                        }
                    }
                    
                    // Save CSV and present share sheet
                    saveAndShareCSV(csvString: csvString)
                }
            }
        }
    }
    
    func parseAnimal(data: [String: Any]) -> Animal? {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let species = data["animalType"] as? String,
            let notesData = data["notes"] as? [[String: Any]],
            let logsData = data["logs"] as? [[String: Any]]
        else {
            print("Missing required fields in data: \(data)")
            return nil
        }
        
        let notes = notesData.compactMap { noteData -> Note? in
            guard
                let id = noteData["id"] as? String,
                let date = noteData["date"] as? Double,
                let note = noteData["note"] as? String
            else {
                print("Missing required fields in noteData: \(noteData)")
                return nil
            }
            return Note(id: id, date: date, note: note, user: noteData["user"] as? String)
        }
        
        let logs = logsData.compactMap { logData -> Log? in
            guard
                let id = logData["id"] as? String,
                let startTime = logData["startTime"] as? Double,
                let endTime = logData["endTime"] as? Double
            else {
                print("Missing required fields in logData: \(logData)")
                return nil
            }
            return Log(id: id, startTime: startTime, endTime: endTime, user: logData["user"] as? String, shortReason: logData["shortReason"] as? String)
        }
        
        let tags = data["tags"] as? [String: Int] ?? [:]
        
        return Animal(
            id: id,
            aggressionRating: data["aggressionRating"] as? Int,
            name: name,
            animalType: AnimalType(rawValue: species) ?? .Cat,
            location: data["location"] as? String ?? "",
            alert: data["alert"] as? String ?? "",
            canPlay: data["canPlay"] as? Bool ?? false,
            inCage: data["inCage"] as? Bool ?? false,
            startTime: data["startTime"] as? Double ?? 0,
            notes: notes,
            logs: logs,
            tags: tags,
            photos: [] // Assuming photos are not included in this example
        )
    }
    
    func formatAnimalToCSV(animal: Animal) -> String {
        var csvRows = [String]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let notes = Array(animal.notes.dropFirst())
        let logs = Array(animal.logs.dropFirst())
        
        let maxRows = max(notes.count, logs.count)
        
        for i in 0..<maxRows {
            let note = i < notes.count ? notes[i] : nil
            let log = i < logs.count ? logs[i] : nil
            
            let noteDateString = note != nil ? dateFormatter.string(from: Date(timeIntervalSince1970: note!.date)) : ""
            let logStartDateString = log != nil ? dateFormatter.string(from: Date(timeIntervalSince1970: log!.startTime)) : ""
            let logEndDateString = log != nil ? dateFormatter.string(from: Date(timeIntervalSince1970: log!.endTime)) : ""
            
            let row = "\(i == 0 ? animal.id : ""),\(i == 0 ? animal.name : ""),\(i == 0 ? animal.animalType.rawValue : ""),\(note?.note ?? ""),\(noteDateString),\(note?.user ?? ""),\(logStartDateString),\(logEndDateString),\(log?.user ?? "")\n"
            csvRows.append(row)
        }
        
        return csvRows.joined()
    }


    
    func saveAndShareCSV(csvString: String) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            showLoading = false
            return
        }
        
        let filePath = documentDirectory.appendingPathComponent("animals_data.csv")
        
        do {
            try csvString.write(to: filePath, atomically: true, encoding: .utf8)
            if fileManager.fileExists(atPath: filePath.path) {
                DispatchQueue.main.async {
                    self.showLoading = false
                    self.shareItems = [filePath]
                    self.showShareSheet = true
                }
                print("CSV saved to \(filePath)")
            } else {
                print("File does not exist at path: \(filePath)")
                DispatchQueue.main.async {
                    self.showLoading = false
                }
            }
        } catch {
            print("Failed to create file: \(error)")
            DispatchQueue.main.async {
                self.showLoading = false
            }
        }
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
