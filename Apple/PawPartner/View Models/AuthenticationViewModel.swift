import FirebaseFirestore
import Foundation
import SwiftUI
import FirebaseAuth

class AuthenticationViewModel: ObservableObject {
    static let shared = AuthenticationViewModel()

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

    @Published var isSignedIn = false
    @Published var showLoginSuccess = false
    @Published var signUpForm = ""

    @Published var reportsDay: String = "Never"
    @Published var reportsEmail: String = ""
    @Published var catTags: [String] = []
    @Published var dogTags: [String] = []
    @Published var earlyReasons: [String] = []
    @Published var filterOptions: [String] = []
    @Published var software: String = ""
    @Published var shelter: String = ""
    @Published var mainFilter: String = ""
    @Published var syncFrequency: String = ""
    @Published var apiKey: String = ""
    @Published var secondarySortOptions: [String] = []
    @Published var groupOptions: [String] = []

    @Published var shelterID = ""
    @AppStorage("accountType") var accountType = "volunteer"
    @Published var name = ""

    @AppStorage("volunteerVideo") var volunteerVideo = ""
    @AppStorage("staffVideo") var staffVideo = ""
    @AppStorage("guidedAccessVideo") var guidedAccessVideo = ""

    @Published var locationSettings = LocationSettings(center: GeoPoint(latitude: 0, longitude: 0), enabled: false, radius: 0, zoomLevel: 0)

    var handle: AuthStateDidChangeListenerHandle?
    var signUpListener: ListenerRegistration?
    var userListener: ListenerRegistration?
    var dataListener: ListenerRegistration?
    var volunteerSettingsListener: ListenerRegistration?

    private var listenersSetUp = false // Flag to check if listeners are already set up

    init() {
        isSignedIn = Auth.auth().currentUser != nil

        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.handleAuthStateChange(user: user)
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func removeListeners() {
        signUpListener?.remove()
        dataListener?.remove()
        volunteerSettingsListener?.remove()
        listenersSetUp = false // Reset flag when listeners are removed
    }

    func fetchSignUpForm() {
        signUpListener = Firestore.firestore().collection("Stats").document("AppInformation").addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            self?.signUpForm = data["signUpForm"] as? String ?? ""
            self?.volunteerVideo = data["volunteerVideo"] as? String ?? ""
            self?.staffVideo = data["staffVideo"] as? String ?? ""
            self?.guidedAccessVideo = data["guidedAccessVideo"] as? String ?? ""
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            removeListeners()  // Ensure listeners are removed on sign out
            shelterID = ""     // Reset shelterID on sign out
            isSignedIn = false // Update isSignedIn status
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    func verifyPassword(password: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(false)
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                print("Error in reauthentication: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    private func handleAuthStateChange(user: User?) {
        if let user = user {
            print("User \(user.uid) signed in")
            self.isSignedIn = true
            fetchSocietyID(forUser: user.uid) { (result) in
                switch result {
                case .success(let id):
                    self.shelterID = id
                    print("Shelter ID: \(id)")
                    self.setupListeners(theUserID: user.uid)
                case .failure(let error):
                    print("Failed to fetch society ID: \(error.localizedDescription)")
                    self.shelterID = ""
                }
            }
        } else {
            print("User signed out")
            self.isSignedIn = false
            removeListeners()
            self.shelterID = ""
        }
    }

    func setupListeners(theUserID: String) {
        guard !listenersSetUp else { return } // Return if listeners are already set up

        print("Setting up listeners")
        listenersSetUp = true // Set the flag to true once listeners are set up

        userListener = Firestore.firestore().collection("Users").document(theUserID)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching user data: \(error)")
                    return
                }
                guard let data = snapshot?.data() else {
                    print("No data found for document")
                    return
                }
                self?.shelterID = data["societyID"] as? String ?? ""
                self?.accountType = data["type"] as? String ?? "volunteer"
                self?.name = data["name"] as? String ?? ""

                if self?.accountType == "volunteer" {
                    self?.setupVolunteerSettingsListener()
                }

                // Ensure shelterID is not empty before setting up the data listener
                if let shelterID = self?.shelterID, !shelterID.isEmpty {
                    self?.setupDataListener(shelterID: shelterID)
                } else {
                    print("shelterID is empty, skipping data listener setup")
                }
            }
    }

    private func setupVolunteerSettingsListener() {
        guard !shelterID.isEmpty else {
            print("Shelter ID is empty, skipping volunteer settings listener setup")
            return
        }

        volunteerSettingsListener = Firestore.firestore().collection("Societies").document(shelterID).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching volunteer settings: \(error)")
                return
            }
            guard let data = snapshot?.data()?["VolunteerSettings"] as? [String: Any] else {
                print("No volunteer settings found")
                return
            }
            DispatchQueue.main.async {
                self?.updateVolunteerSettings(with: data)
            }
        }
    }

    private func setupDataListener(shelterID: String) {
        guard !shelterID.isEmpty else {
            print("Shelter ID is empty, skipping data listener setup")
            return
        }

        dataListener = Firestore.firestore().collection("Societies").document(shelterID)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching society data: \(error)")
                    return
                }
                guard let data = snapshot?.data() else {
                    print("No data found for document")
                    return
                }
                self?.updateProperties(with: data)
            }
    }

    private func updateVolunteerSettings(with data: [String: Any]) {
        let settings = VolunteerSettings(from: data)
        // Update UserDefaults with the latest settings from Firestore
        settings.applyToUserDefaults()
    }

    func updateProperties(with data: [String: Any]) {
        DispatchQueue.main.async {
            self.reportsDay = data["reportsDay"] as? String ?? ""
            self.reportsEmail = data["reportsEmail"] as? String ?? ""
            self.earlyReasons = data["earlyReasons"] as? [String] ?? []
            self.catTags = data["catTags"] as? [String] ?? []
            self.dogTags = data["dogTags"] as? [String] ?? []
            self.software = data["software"] as? String ?? ""
            self.shelter = data["shelter"] as? String ?? ""
            self.mainFilter = data["mainFilter"] as? String ?? ""
            self.syncFrequency = data["syncFrequency"] as? String ?? ""
            self.apiKey = data["apiKey"] as? String ?? ""
            self.secondarySortOptions = data["secondarySortOptions"] as? [String] ?? []
            self.groupOptions = data["groupOptions"] as? [String] ?? []

            if let locationData = data["georestriction"] as? [String: Any] {
                self.locationSettings = LocationSettings(from: locationData)
                // Debug output for LocationSettings
                print("Updated location settings: \(self.locationSettings)")
            }
        }
    }

    func fetchSocietyID(forUser userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("Users").document(userID).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists, let data = document.data(),
                   let societyID = data["societyID"] as? String {
                    completion(.success(societyID))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "SocietyID not found"])))
                }
            }
        }
    }

    func updatePassword(oldPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                print("Error in reauthentication: \(error.localizedDescription)")
                return
            }
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    print("Error updating password: \(error.localizedDescription)")
                } else {
                    print("Password updated successfully!")
                }
            }
        }
    }
}

struct VolunteerSettings {
    var adminMode: Bool
    var QRMode: Bool
    var sortBy: SortBy
    var minimumDuration: Int
    var cardsPerPage: Int
    var customFormURL: String
    var isCustomFormOn: Bool
    var linkType: String
    var showNoteDates: Bool
    var requireName: Bool
    var showAllAnimals: Bool
    var createLogsAlways: Bool
    var requireReason: Bool
    var showSearchBar: Bool
    var secondarySortOption: String
    var enableAutomaticPutBack: Bool
    var automaticPutBackHours: Int
    var automaticPutBackIgnoreVisit: Bool
    var groupOption: String
    var showBulkTakeOut: Bool
    var showFilterOptions: Bool

    init(from data: [String: Any]) {
        self.adminMode = data["adminMode"] as? Bool ?? false
        self.QRMode = data["QRMode"] as? Bool ?? true
        self.sortBy = SortBy(rawValue: data["sortOption"] as? String ?? SortBy.lastLetOut.rawValue) ?? .lastLetOut
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
        self.groupOption = data["groupOption"] as? String ?? ""
        self.showBulkTakeOut = data["showBulkTakeOut"] as? Bool ?? false
        self.showFilterOptions = data["showFilterOptions"] as? Bool ?? false
    }

    func applyToUserDefaults() {
        UserDefaults.standard.set(adminMode, forKey: "adminMode")
        UserDefaults.standard.set(QRMode, forKey: "QRMode")
        UserDefaults.standard.set(sortBy.rawValue, forKey: "sortBy")
        UserDefaults.standard.set(minimumDuration, forKey: "minimumDuration")
        UserDefaults.standard.set(cardsPerPage, forKey: "cardsPerPage")
        UserDefaults.standard.set(customFormURL, forKey: "customFormURL")
        UserDefaults.standard.set(isCustomFormOn, forKey: "isCustomFormOn")
        UserDefaults.standard.set(linkType, forKey: "linkType")
        UserDefaults.standard.set(showNoteDates, forKey: "showNoteDates")
        UserDefaults.standard.set(requireName, forKey: "requireName")
        UserDefaults.standard.set(showAllAnimals, forKey: "showAllAnimals")
        UserDefaults.standard.set(createLogsAlways, forKey: "createLogsAlways")
        UserDefaults.standard.set(requireReason, forKey: "requireReason")
        UserDefaults.standard.set(showSearchBar, forKey: "showSearchBar")
        UserDefaults.standard.set(secondarySortOption, forKey: "secondarySortOption")
        UserDefaults.standard.set(enableAutomaticPutBack, forKey: "enableAutomaticPutBack")
        UserDefaults.standard.set(automaticPutBackHours, forKey: "automaticPutBackHours")
        UserDefaults.standard.set(automaticPutBackIgnoreVisit, forKey: "automaticPutBackIgnoreVisit")
        UserDefaults.standard.set(groupOption, forKey: "groupOption")
        UserDefaults.standard.set(showBulkTakeOut, forKey: "showBulkTakeOut")
        UserDefaults.standard.set(showFilterOptions, forKey: "showFilterOptions")
    }
}

struct LocationSettings {
    var center: GeoPoint?
    var enabled: Bool
    var radius: Double?
    var zoomLevel: Double

    init(center: GeoPoint? = GeoPoint(latitude: 0, longitude: 0), enabled: Bool = false, radius: Double? = 0, zoomLevel: Double = 0) {
        self.center = center
        self.enabled = enabled
        self.radius = radius
        self.zoomLevel = zoomLevel
    }

    init(from data: [String: Any]) {
        self.center = data["center"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0)
        self.enabled = data["enabled"] as? Bool ?? false
        self.radius = data["radius"] as? Double ?? 0
        self.zoomLevel = data["zoomLevel"] as? Double ?? 0
    }
}
