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
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("QRMode") var QRMode = true
    @AppStorage("volunteerVideo") var volunteerVideo: String = ""
    @AppStorage("staffVideo") var staffVideo: String = ""
    @AppStorage("guidedAccessVideo") var guidedAccessVideo: String = ""
//    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("lastSync") var lastSync: String = ""
    @AppStorage("updateAppURL") var updateAppURL: String = ""
    @AppStorage("latestVersion") var latestVersion: String = ""
    @AppStorage("adminMode") var adminMode = true
//    @AppStorage("accountType") var accountType = "volunteer"


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

//    private var isVisitorBinding: Binding<Bool> {
//        Binding<Bool>(
//            get: { self.mode == "visitor" },
//            set: { newValue in
//                self.mode = newValue ? "visitor" : "visitorAdmin"
//            }
//        )
//    }
//
//    private var isAdminBinding: Binding<Bool> {
//        Binding<Bool>(
//            get: { self.mode == "volunteerAdmin" },
//            set: { newValue in
//                self.mode = newValue ? "volunteerAdmin" : "volunteer"
//            }
//        )
//    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                    Section(header: Text("Account Details")) {
                        if authViewModel.shelter != "" {
                            HStack {
                                Text("Shelter:")
                                    .bold()
                                Text(authViewModel.shelter)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if authenticationViewModel.shelterID != "" {
                            HStack {
                                Text("Shelter ID:")
                                    .bold()
                                Text(authenticationViewModel.shelterID)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if authViewModel.software != "" {
                            HStack {
                                Text("Management Software:")
                                    .bold()
                                Text(authViewModel.software)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if authViewModel.apiKey != "" {
                            HStack {
                                Text("API Key:")
                                    .bold()
                                Text(authViewModel.apiKey)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if authViewModel.mainFilter != "" {
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
                
                
                Section("Account Settings") {
                    NavigationLink(destination: AccountSetupView()) {
                        HStack {
                            Image(systemName: "shared.with.you")
                            Text("Account Setup")
                        }
                    }
                    NavigationLink(destination: VolunteerAccountsView()) {
                        HStack {
                            Image(systemName: "person.crop.rectangle.stack")
                            Text("Volunteer Accounts")
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
                        Toggle("Admin Mode", isOn: $adminMode)
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
                    if latestVersion != appVersion {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(.red)
                            Text("Your app is not up to date. Please update when convenient.")
                                .foregroundStyle(.red)
                            Link("Update", destination: (URL(string: updateAppURL) ?? URL(string: "https://pawparnter.app"))!)
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
//        mode = "logIn"
    }
    
    func downloadAllData() {
        showLoading = true
        
        let db = Firestore.firestore()
        let documentRef = db.collection("Societies").document(authenticationViewModel.shelterID)
        
        documentRef.getDocument { (document, error) in
            guard let document = document, document.exists else {
                print("Document does not exist")
                showLoading = false
                return
            }
            
            var csvString = "id,name,species,note,note date,note person,log start,log end,log person\n"
            
            fetchAllAnimals(from: documentRef.collection("Cats")) { catCSV in
                csvString.append(contentsOf: catCSV)
                
                fetchAllAnimals(from: documentRef.collection("Dogs")) { dogCSV in
                    csvString.append(contentsOf: dogCSV)
                    
                    // Save CSV and present share sheet
                    saveAndShareCSV(csvString: csvString)
                }
            }
        }
    }

    func fetchAllAnimals(from collection: CollectionReference, lastDocument: DocumentSnapshot? = nil, completion: @escaping (String) -> Void) {
        var query: Query = collection
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        query.limit(to: 1000).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion("")
                return
            }
            
            var csvString = ""
            
            for document in querySnapshot!.documents {
                let data = document.data()
                if let animal = parseAnimal(data: data) {
                    csvString.append(contentsOf: formatAnimalToCSV(animal: animal))
                }
            }
            
            if let lastDocument = querySnapshot?.documents.last, querySnapshot?.documents.count == 1000 {
                // Fetch next batch
                fetchAllAnimals(from: collection, lastDocument: lastDocument) { nextBatchCSV in
                    csvString.append(contentsOf: nextBatchCSV)
                    completion(csvString)
                }
            } else {
                completion(csvString)
            }
        }
    }

    func parseAnimal(data: [String: Any]) -> Animal? {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let species = data["animalType"] as? String
        else {
            print("Missing required fields in data: \(data)")
            return nil
        }
        
        let notesData = data["notes"] as? [[String: Any]] ?? []
        let logsData = data["logs"] as? [[String: Any]] ?? []
        
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
            
            let row = "\(i == 0 ? escapeCSV(animal.id) : ""),\(i == 0 ? escapeCSV(animal.name) : ""),\(i == 0 ? escapeCSV(animal.animalType.rawValue) : ""),\(escapeCSV(note?.note ?? "")),\(noteDateString),\(escapeCSV(note?.user ?? "")),\(logStartDateString),\(logEndDateString),\(escapeCSV(log?.user ?? "")),\(escapeCSV(log?.shortReason ?? ""))\n"
            csvRows.append(row)
        }
        
        if maxRows == 0 {
            let row = "\(escapeCSV(animal.id)),\(escapeCSV(animal.name)),\(escapeCSV(animal.animalType.rawValue)),,,,,,\n"
            csvRows.append(row)
        }
        
        return csvRows.joined()
    }

    func escapeCSV(_ field: String) -> String {
        var escapedField = field
        if escapedField.contains("\"") {
            escapedField = escapedField.replacingOccurrences(of: "\"", with: "\"\"")
        }
        if escapedField.contains(",") || escapedField.contains("\n") || escapedField.contains("\"") {
            escapedField = "\"\(escapedField)\""
        }
        return escapedField
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
