import AlertToast
import SwiftUI
import Firebase
import FirebaseFirestore

//enum SortBy: String, CaseIterable {
//    case lastLetOut = "Last Let Out"
//    case name = "Name"
//    case age = "Age"
//    // Add other cases as needed
//}

struct DeviceSettingsView: View {
    @AppStorage("volunteerSettingsEnabled") var volunteerSettingsEnabled = false

    @AppStorage("minimumDuration") var minimumDuration = 5
    @AppStorage("cardsPerPage") var cardsPerPage = 30
    @AppStorage("customFormURL") var customFormURL = ""
    @AppStorage("isCustomFormOn") var isCustomFormOn = false
    @AppStorage("linkType") var linkType = "QR Code"
    @AppStorage("showNoteDates") var showNoteDates = true
    @AppStorage("requireName") var requireName = false
    @AppStorage("showAllAnimals") var showAllAnimals = false
    @AppStorage("createLogsAlways") var createLogsAlways = false
    @AppStorage("requireReason") var requireReason = false
    @AppStorage("showSearchBar") var showSearchBar = false
    @AppStorage("secondarySortOption") var secondarySortOption = ""
    @AppStorage("enableAutomaticPutBack") var enableAutomaticPutBack = false
    @AppStorage("automaticPutBackHours") var automaticPutBackHours = 3
    @AppStorage("automaticPutBackIgnoreVisit") var automaticPutBackIgnoreVisit = true
    @AppStorage("groupOption") var groupOption = ""
    @AppStorage("showBulkTakeOut") var showBulkTakeOut = false
    @AppStorage("sortBy") var sortBy: SortBy = .lastLetOut
    @AppStorage("QRMode") var QRMode = true
    @AppStorage("adminMode") var adminMode = true
    @AppStorage("showFilterOptions") var showFilterOptions = false
    @AppStorage("requireLetOutType") var requireLetOutType = false

    @ObservedObject var viewModel = AuthenticationViewModel.shared
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    
    @State private var showLoading = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    let linkTypes = ["QR Code", "Open In App"]

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $volunteerSettingsEnabled) {
                    SettingElement(title: "Apply Device Settings To Volunteer Accounts: \(volunteerSettingsEnabled ? "Enabled" : "Disabled")", explanation: "Apply all the settings on this page your volunteer accounts.")
                }
                    .tint(.customBlue)
                    .onChange(of: volunteerSettingsEnabled) { _ in saveSettings() }
            }
            Toggle(isOn: $adminMode) {
                SettingElement(title: "Admin Mode: \(adminMode ? "Enabled" : "Disabled")", explanation: "Turn on when allowing someone else to use your device. This will disable settings and destructive actions until you enter your password.")
            }
                .tint(.customBlue)
                .onChange(of: adminMode) { _ in saveSettings() }
            Toggle(isOn: $QRMode) {
                SettingElement(title: "QR Codes: \(QRMode ? "Enabled" : "Disabled")", explanation: "Allow users to add photos by scanning a QR Code when the device is in Admin Mode")
            }
                .tint(.customBlue)
                .onChange(of: QRMode) { _ in saveSettings() }
            Picker(selection: $sortBy) {
                ForEach(SortBy.allCases, id: \.self) { sortOption in
                    Text(sortOption.rawValue).tag(sortOption)
                }
                .onChange(of: sortBy) { _ in saveSettings() }
            } label: {
                Button { } label: {
                    SettingElement(title: "Sort Options", explanation: "Decide how the animals should be sorted. \"Last Let Out\" is the recommended setting.")
                        .foregroundStyle(.black)
                }
            }
            Button {
                downloadAllData()
            } label: {
                SettingElement(title: "Download All Data", explanation: "Download all data for all of your animals in a .csv file")
            }
            Section {
                Stepper(value: $minimumDuration, in: 0...30, step: 1) {
                    SettingElement(title: "Minimum Log Duration: \(minimumDuration == 1 ? "\(minimumDuration) minute" : "\(minimumDuration) minutes")", explanation: "Sets the minimum duration for a visit. If a volunteer takes out an animal for a visit lasting less than this amount, it will show an error.")
                }
                    .onChange(of: minimumDuration) { _ in saveSettings() }
            }
            
            Section {
                Toggle(isOn: $enableAutomaticPutBack) {
                    SettingElement(title: "Automatically Put Back Animals: \(enableAutomaticPutBack ? "Enabled" : "Disabled")", explanation: "Automatically put back animals that have been out of their kennel for a period of time.")
                }
                    .tint(.customBlue)
                    .onChange(of: enableAutomaticPutBack) { _ in saveSettings() }
                Toggle(isOn: $automaticPutBackIgnoreVisit) {
                    SettingElement(title: "Ignore Visit When Automatically Put Back: \(automaticPutBackIgnoreVisit ? "Enabled" : "Disabled")", explanation: "Ignore the visit and don't create a log when an animal is automatically put back.")
                }
                    .tint(.customBlue)
                    .disabled(!enableAutomaticPutBack)
                    .onChange(of: automaticPutBackIgnoreVisit) { _ in saveSettings() }
                Stepper(value: $automaticPutBackHours, in: 1...24, step: 1) {
                    SettingElement(title: "Put Back After: \(automaticPutBackHours == 1 ? "\(automaticPutBackHours) hour" : "\(automaticPutBackHours) hours")", explanation: "Automatically put back animals that have been out of their kennel for a period of time.")
                }
                    .disabled(!enableAutomaticPutBack)
                    .onChange(of: automaticPutBackHours) { _ in saveSettings() }
            } 

            Section {
                Toggle(isOn: $requireLetOutType) {
                    SettingElement(title: "Show \"Let Out Type\" Prompt: \(requireLetOutType ? "Enabled" : "Disabled")", explanation: "When a user takes out an animal, they will be prompted to specify what the animal will be doing. For example, whether they'll be going for a walk or in a playgroup. You can specify these options in Shelter Settings")
                }
                .tint(.customBlue)
                .onChange(of: requireLetOutType) { _ in saveSettings() }

            }
            
            Section {
                Toggle(isOn: $requireReason) {
                    SettingElement(title: "Require Reason When Under Minimum Duration: \(requireReason ? "Enabled" : "Disabled")", explanation: "Require users to a add a reason for why they put the animal back before the minimum duration. You can create a list of reasons for them to choose from in Shelter Setttings.")
                }
                    .tint(.customBlue)
                    .onChange(of: requireReason) { _ in saveSettings() }
            }
            
            Section {
                Toggle(isOn: $createLogsAlways) {
                    SettingElement(title: "Create Logs Even Under Minimum Duration: \(createLogsAlways ? "Enabled" : "Disabled")", explanation: "Create logs for animals that are put back before the minimum duration.")
                }
                    .tint(.customBlue)
                    .onChange(of: createLogsAlways) { _ in saveSettings() }
            }

            Section {
                Stepper(value: $cardsPerPage, in: 1...200, step: 1) {
                    SettingElement(title: "Cards Per Page: \(cardsPerPage)", explanation: "Cards are split into pages to ensure smooth performance. Depending on your device, you may be able to raise this number. However, if you notice the app is running slowing, you should lower this number until it runs smoothly.")
                }
                    .onChange(of: cardsPerPage) { _ in saveSettings() }
            }
            Section {
                Toggle(isOn: $showNoteDates) {
                    SettingElement(title: "Show Note Dates: \(showNoteDates ? "Enabled" : "Disabled")", explanation: "Display the date notes were created")
                }
                    .tint(.customBlue)
                    .onChange(of: showNoteDates) { _ in saveSettings() }
            }
            Section {
                Toggle(isOn: $requireName) {
                    SettingElement(title: "Require Name: \(requireName ? "Enabled" : "Disabled")", explanation: "Before an animal can be taken out, you must enter your name if you are not logged in to your volunteer account.")
                }
                    .tint(.customBlue)
                    .onChange(of: requireName) { _ in saveSettings() }
            }
            Section {
                Toggle(isOn: $isCustomFormOn) {
                    SettingElement(title: "Custom Form: \(isCustomFormOn ? "Enabled" : "Disabled")", explanation: "If you would like to prompt users to fill out a custom form of your choice after visiting with an animal, add the url and turn on the toggle. This will display a \"Custom Form\" button on the \"Thank You\" pop up after putting an animal back. If the button doesn't work, make sure your url begins with https://")
                }
                    .tint(.customBlue)
                    .onChange(of: isCustomFormOn) { _ in saveSettings() }
                TextField("https://example.com", text: $customFormURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(!isCustomFormOn)
                    .foregroundStyle(isCustomFormOn ? .primary : .secondary)
                    .onChange(of: customFormURL) { _ in saveSettings() }
                Picker(selection: $linkType) {
                    ForEach(linkTypes, id: \.self) {
                        Text($0)
                    }
                } label: {
                    Button {
                        
                    } label: {
                        SettingElement(title: "Button Type", explanation: "How you want the link to be displayed")
                            .foregroundStyle(.black)
                    }
                }
                .foregroundStyle(isCustomFormOn ? .primary : .secondary)
                .onChange(of: linkType) { _ in saveSettings() }
            }
            
            Section {
                Toggle(isOn: $showAllAnimals) {
                    SettingElement(title: "Display All Animals: \(showAllAnimals ? "Enabled" : "Disabled")", explanation: "Display all animals including ones you've selected to filter out. Filtered animals will be gray and won't be able to be taken out.")
                }
                    .tint(.customBlue)
                    .onChange(of: showAllAnimals) { _ in saveSettings() }
            }
            Section {
                Toggle(isOn: $showSearchBar) {
                    SettingElement(title: "Show Search Bar: \(showSearchBar ? "Enabled" : "Disabled")", explanation: "Search animals by name, notes, breed, etc.")
                }
                    .tint(.customBlue)
                    .onChange(of: showSearchBar) { _ in saveSettings() }
            }

            if !viewModel.groupOptions.isEmpty {
                Section {
                    Toggle(isOn: $showFilterOptions) {
                        SettingElement(title: "Show Filter Options", explanation: "Allow users to add their own filter in the Animal tab.")
                    }
                    .tint(.customBlue)
                    .onChange(of: showFilterOptions) { _ in saveSettings() }
                }
                
                Section {
                    Picker(selection: $groupOption) {
                        Text("").tag("")
                        ForEach(viewModel.groupOptions, id: \.self) {
                            Text($0)
                        }
                    } label: {
                        Button {
                            
                        } label: {
                            SettingElement(title: "Group By", explanation: "Group animals by categories of your choice.")
                                .foregroundStyle(.black)
                        }
                        
                    }
                    .onChange(of: groupOption) { _ in saveSettings() }
                    Toggle(isOn: $showBulkTakeOut) {
                        SettingElement(title: "Show \"Bulk Take Out\" Button", explanation: "This allows users to take out and put back all the animals in a group at the same time.")
                    }
                        .tint(.customBlue)
                        .onChange(of: showBulkTakeOut) { _ in saveSettings() }
                }
            }

            if !viewModel.secondarySortOptions.isEmpty {
                Section {
                    Picker(selection: $secondarySortOption) {
                        Text("").tag("")
                        ForEach(viewModel.secondarySortOptions, id: \.self) {
                            Text($0)
                        }
                    } label: {
                        Button {
                            
                        } label: {
                            SettingElement(title: "Secondary Sort", explanation: "Sort animals by categories of your choice.")
                                .foregroundStyle(.black)
                        }
                    }
                    .onChange(of: secondarySortOption) { _ in saveSettings() }
                }
            }
        }
        .navigationTitle("Device Settings")
        .toast(isPresenting: $showLoading) {
            AlertToast(displayMode: .alert, type: .loading)
        }
        .sheet(isPresented: Binding(
            get: { showShareSheet },
            set: { showShareSheet = $0 }
        )) {
            ActivityView(activityItems: shareItems)
        }
        .onAppear {
            if volunteerSettingsEnabled {
                loadSettingsFromFirestore()
            }
        }
    }
    
    private func saveSettings() {
        if volunteerSettingsEnabled {
            saveSettingsToFirestore()
        } else {
            // Settings are saved to @AppStorage by default
        }
    }
    
    private func saveSettingsToFirestore() {
        let db = Firestore.firestore()
        let settings: [String: Any] = [
            "adminMode": adminMode,
            "QRMode": QRMode,
            "sortBy": sortBy.rawValue,
            "minimumDuration": minimumDuration,
            "cardsPerPage": cardsPerPage,
            "customFormURL": customFormURL,
            "isCustomFormOn": isCustomFormOn,
            "linkType": linkType,
            "showNoteDates": showNoteDates,
            "requireName": requireName,
            "showAllAnimals": showAllAnimals,
            "createLogsAlways": createLogsAlways,
            "requireReason": requireReason,
            "showSearchBar": showSearchBar,
            "secondarySortOption": secondarySortOption,
            "enableAutomaticPutBack": enableAutomaticPutBack,
            "automaticPutBackHours": automaticPutBackHours,
            "automaticPutBackIgnoreVisit": automaticPutBackIgnoreVisit,
            "showFilterOptions": showFilterOptions,
            "groupOption": groupOption,
            "showBulkTakeOut": showBulkTakeOut,
            "requireLetOutType": requireLetOutType
        ]
        db.collection("Societies").document(viewModel.shelterID).setData(["VolunteerSettings": settings], merge: true) { error in
            if let error = error {
                print("Error saving settings to Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadSettingsFromFirestore() {
        let db = Firestore.firestore()
        let docRef = db.collection("Societies").document(viewModel.shelterID)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()?["VolunteerSettings"] as? [String: Any] ?? [:]
                DispatchQueue.main.async {
                    self.adminMode = true
                    self.QRMode = data["QRMode"] as? Bool ?? true
                    self.sortBy = SortBy(rawValue: data["sortBy"] as? String ?? SortBy.lastLetOut.rawValue) ?? .lastLetOut
                    
                    self.minimumDuration = data["minimumDuration"] as? Int ?? 5
                    self.cardsPerPage = data["cardsPerPage"] as? Int ?? 30
                    self.customFormURL = data["customFormURL"] as? String ?? ""
                    self.isCustomFormOn = data["isCustomFormOn"] as? Bool ?? false
                    self.linkType = data["linkType"] as? String ?? "QR Code"
                    self.showNoteDates = data["showNoteDates"] as? Bool ?? true
                    self.requireName = data["requireName"] as? Bool ?? false
                    self.showAllAnimals = data["showAllAnimals"] as? Bool ?? false
                    self.createLogsAlways = data["createLogsAlways"] as? Bool ?? false
                    self.requireReason = data["requireReason"] as? Bool ?? false
                    self.showSearchBar = data["showSearchBar"] as? Bool ?? false
                    self.secondarySortOption = data["secondarySortOption"] as? String ?? ""
                    self.enableAutomaticPutBack = data["enableAutomaticPutBack"] as? Bool ?? false
                    self.automaticPutBackHours = data["automaticPutBackHours"] as? Int ?? 3
                    self.automaticPutBackIgnoreVisit = data["automaticPutBackIgnoreVisit"] as? Bool ?? true
                    self.showFilterOptions = data["showFilterOptions"] as? Bool ?? false
                    self.groupOption = data["groupOption"] as? String ?? ""
                    self.showBulkTakeOut = data["showBulkTakeOut"] as? Bool ?? false
                    self.requireLetOutType = data["requireLetOutType"] as? Bool ?? false
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func downloadAllData() {
        showLoading = true
        
        let db = Firestore.firestore()
        let documentRef = db.collection("Societies").document(viewModel.shelterID)
        
        documentRef.getDocument { (document, error) in
            guard let document = document, document.exists else {
                print("Document does not exist")
                showLoading = false
                return
            }
            
            var csvString = "id,name,species,note,note date,note person,log start,log end,log person,short reason,log type\n"
            
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
            return Log(id: id, startTime: startTime, endTime: endTime, user: logData["user"] as? String, shortReason: logData["shortReason"] as? String, letOutType: logData["letOutType"] as? String)
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
            
            let row = "\(i == 0 ? escapeCSV(animal.id) : ""),\(i == 0 ? escapeCSV(animal.name) : ""),\(i == 0 ? escapeCSV(animal.animalType.rawValue) : ""),\(escapeCSV(note?.note ?? "")),\(noteDateString),\(escapeCSV(note?.user ?? "")),\(logStartDateString),\(logEndDateString),\(escapeCSV(log?.user ?? "")),\(escapeCSV(log?.shortReason ?? "")),\(escapeCSV(log?.letOutType ?? ""))\n"
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
}
