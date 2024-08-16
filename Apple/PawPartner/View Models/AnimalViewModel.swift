import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Foundation

class AnimalViewModel: ObservableObject {
    static let shared = AnimalViewModel()
    
    @Published var sortedDogs: [Animal] = []
    @Published var sortedCats: [Animal] = []
    @Published var sortedGroupDogs: [Animal] = []
    @Published var sortedGroupCats: [Animal] = []
    
    @Published var sortedVisitorDogs: [Animal] = []
    @Published var sortedVisitorCats: [Animal] = []
    
    @AppStorage("secondarySortOption") var secondarySortOption = ""
//    @AppStorage("groupsEnabled") var groupsEnabled = false
    @AppStorage("groupOption") var groupOption = ""

    @Published var showRequireLetOutType = false
    @Published var showRequireReason = false
    @Published var showRequireName = false
    @Published var showLogTooShort = false
    @Published var showLogCreated = false
    @Published var showAggressionRating = false
    @Published var showAnimalAlert = false
    @Published var showQRCode = false
    @Published var showAddNote = false
    @Published var cats = [Animal]()
    @Published var dogs = [Animal]()
    @Published var animal: Animal = Animal.dummyAnimal
    @Published var toastAddNote = false
    
    var catListener: ListenerRegistration?
    var dogListener: ListenerRegistration?
    var societyListener: ListenerRegistration?
    var statsListener: ListenerRegistration?
    
//    var groupAnimals = true
//    var sortBySecondaryOption = true
//    var sortByPrimaryOption = true
    
    @AppStorage("showAllAnimals") var showAllAnimals = false
    @AppStorage("guidedAccessVideo") var guidedAccessVideo: String = ""
    @AppStorage("volunteerVideo") var volunteerVideo: String = ""
    @AppStorage("staffVideo") var staffVideo: String = ""
    @AppStorage("donationURL") var donationURL: String = ""
    @AppStorage("animalNotesJotformURL") var animalNotesJotformURL: String = ""

    @AppStorage("lastSync") var lastSync: String = DateFormatter().string(from: Date())
    @AppStorage("lastCatSync") var lastCatSync: String = DateFormatter().string(from: Date())
    @AppStorage("lastDogSync") var lastDogSync: String = DateFormatter().string(from: Date())

    @AppStorage("latestVersion") var latestVersion: String = ""
    @AppStorage("updateAppURL") var updateAppURL: String = ""
    @AppStorage("sortBy") var sortBy: SortBy = .lastLetOut
    @AppStorage("feedbackURL") var feedbackURL: String = ""
    @AppStorage("reportProblemURL") var reportProblemURL: String = ""

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var db = Firestore.firestore()
    
    func sortCats() {
            sortedCats = cats.sorted(by: { cat1, cat2 in
                switch sortBy {
                case .lastLetOut:
                    return cat1.logs.last?.endTime ?? 0 < cat2.logs.last?.endTime ?? 0
                case .playtime24Hours:
                    return cat1.playtimeLast24Hours < cat2.playtimeLast24Hours
                case .playtime7Days:
                    return cat1.playtimeLast7Days < cat2.playtimeLast7Days
                case .playtime30Days:
                    return cat1.playtimeLast30Days < cat2.playtimeLast30Days
                case .playtime90Days:
                    return cat1.playtimeLast90Days < cat2.playtimeLast90Days
                }
            })


            sortedGroupCats = groupAndSortAnimals(cats)
            
            sortedVisitorCats = cats.sorted(by: { cat1, cat2 in
                return cat1.logs.first?.startTime ?? 0 < cat2.logs.first?.startTime ?? 0
            })
        }
        
        func sortDogs() {
            sortedDogs = dogs.sorted(by: { dog1, dog2 in
                switch sortBy {
                case .lastLetOut:
                    return dog1.logs.last?.endTime ?? 0 < dog2.logs.last?.endTime ?? 0
                case .playtime24Hours:
                    return dog1.playtimeLast24Hours < dog2.playtimeLast24Hours
                case .playtime7Days:
                    return dog1.playtimeLast7Days < dog2.playtimeLast7Days
                case .playtime30Days:
                    return dog1.playtimeLast30Days < dog2.playtimeLast30Days
                case .playtime90Days:
                    return dog1.playtimeLast90Days < dog2.playtimeLast90Days
                }
            })
            
            sortedGroupDogs = groupAndSortAnimals(dogs)
            
            sortedVisitorDogs = dogs.sorted(by: { dog1, dog2 in
                return dog1.logs.first?.startTime ?? 0 < dog2.logs.first?.startTime ?? 0
            })
        }
    
    func groupAndSortAnimals(_ animals: [Animal]) -> [Animal] {
           var groupedAnimals: [String: [Animal]] = ["\u{200B}Unknown Group": animals]
           
        if groupOption != "" {
            if groupOption == "Color" {
                groupedAnimals = Dictionary(grouping: animals, by: { $0.colorGroup ?? "\u{200B}Unknown Group" })
            } else if groupOption == "Behavior" {
                groupedAnimals = Dictionary(grouping: animals, by: { $0.behaviorGroup ?? "\u{200B}Unknown Group" })
            } else if groupOption == "Building" {
                groupedAnimals = Dictionary(grouping: animals, by: { $0.buildingGroup ?? "\u{200B}Unknown Group" })
            }
        
        }
           
           // Sort the keys (group names)
           let sortedGroupKeys = groupedAnimals.keys.sorted()

           // Create a new list to hold the sorted animals
           var sortedGroupedAnimals: [Animal] = []

           // Iterate over the sorted group keys
           for key in sortedGroupKeys {
               if let animalsInGroup = groupedAnimals[key] {
                   let sortedAnimalsInGroup: [Animal]
                   
                   // Check if secondarySortOption is not empty and sorting by secondary option is enabled
                   if !secondarySortOption.isEmpty {
                       // Sort by secondarySortOption first, then by let-out time
                       sortedAnimalsInGroup = animalsInGroup.sorted(by: {
                           if secondarySortOption == "Color" {
                               if $0.colorSort == $1.colorSort {
                                   switch sortBy {
                                   case .lastLetOut:
                                       return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   case .playtime24Hours:
                                       return $0.playtimeLast24Hours < $1.playtimeLast24Hours
                                   case .playtime7Days:
                                       return $0.playtimeLast7Days < $1.playtimeLast7Days
                                   case .playtime30Days:
                                       return $0.playtimeLast30Days < $1.playtimeLast30Days
                                   case .playtime90Days:
                                       return $0.playtimeLast90Days < $1.playtimeLast90Days
                                   }
                               }
                               return ($0.colorSort ?? 100) < ($1.colorSort ?? 100)
                           } else if secondarySortOption == "Behavior" {
                               if $0.behaviorSort == $1.behaviorSort {
//                                   return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   switch sortBy {
                                   case .lastLetOut:
                                       return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   case .playtime24Hours:
                                       return $0.playtimeLast24Hours < $1.playtimeLast24Hours
                                   case .playtime7Days:
                                       return $0.playtimeLast7Days < $1.playtimeLast7Days
                                   case .playtime30Days:
                                       return $0.playtimeLast30Days < $1.playtimeLast30Days
                                   case .playtime90Days:
                                       return $0.playtimeLast90Days < $1.playtimeLast90Days
                                   }
                               }
                               return ($0.behaviorSort ?? 100) < ($1.behaviorSort ?? 100)
                           } else if secondarySortOption == "Building" {
                               if $0.behaviorSort == $1.behaviorSort {
//                                   return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   switch sortBy {
                                   case .lastLetOut:
                                       return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   case .playtime24Hours:
                                       return $0.playtimeLast24Hours < $1.playtimeLast24Hours
                                   case .playtime7Days:
                                       return $0.playtimeLast7Days < $1.playtimeLast7Days
                                   case .playtime30Days:
                                       return $0.playtimeLast30Days < $1.playtimeLast30Days
                                   case .playtime90Days:
                                       return $0.playtimeLast90Days < $1.playtimeLast90Days
                                   }
                               }
                               return ($0.behaviorSort ?? 100) < ($1.behaviorSort ?? 100)

                           } else {
                               if $0.secondarySort == $1.secondarySort {
//                                   return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   switch sortBy {
                                   case .lastLetOut:
                                       return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                                   case .playtime24Hours:
                                       return $0.playtimeLast24Hours < $1.playtimeLast24Hours
                                   case .playtime7Days:
                                       return $0.playtimeLast7Days < $1.playtimeLast7Days
                                   case .playtime30Days:
                                       return $0.playtimeLast30Days < $1.playtimeLast30Days
                                   case .playtime90Days:
                                       return $0.playtimeLast90Days < $1.playtimeLast90Days
                                   }
                               }
                               return ($0.secondarySort ?? 100) < ($1.secondarySort ?? 100)
                           }
                       })
                   } else {
                       // Sort by let-out time only if primary sorting is enabled
                       sortedAnimalsInGroup = animalsInGroup.sorted(by: {
//                           $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                           switch sortBy {
                           case .lastLetOut:
                               return $0.logs.last?.endTime ?? 0 < $1.logs.last?.endTime ?? 0
                           case .playtime24Hours:
                               return $0.playtimeLast24Hours < $1.playtimeLast24Hours
                           case .playtime7Days:
                               return $0.playtimeLast7Days < $1.playtimeLast7Days
                           case .playtime30Days:
                               return $0.playtimeLast30Days < $1.playtimeLast30Days
                           case .playtime90Days:
                               return $0.playtimeLast90Days < $1.playtimeLast90Days
                           }
                       })
                   }
                   
                   // Append sorted animals to the final list
                   sortedGroupedAnimals.append(contentsOf: sortedAnimalsInGroup)
               }
           }

           return sortedGroupedAnimals
       }


    
    func postAppVersion(societyID: String, installedVersion: String) {
        let documentReference = db.collection("Societies").document(societyID)
        documentReference.updateData(["installedVersion": installedVersion]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func listenForSocietyLastSyncUpdate(societyID: String) {
        societyListener = db.collection("Societies").document(societyID).addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            if let lastSyncFirebase = data["lastSync"] as? Timestamp { // assuming the lastSync is a Firestore Timestamp
                self?.lastSync = self?.dateFormatter.string(from: lastSyncFirebase.dateValue()) ?? ""
            }
            if let lastSyncFirebase = data["lastCatSync"] as? Timestamp { // assuming the lastSync is a Firestore Timestamp
                self?.lastCatSync = self?.dateFormatter.string(from: lastSyncFirebase.dateValue()) ?? ""
            }
            if let lastSyncFirebase = data["lastDogSync"] as? Timestamp { // assuming the lastSync is a Firestore Timestamp
                self?.lastDogSync = self?.dateFormatter.string(from: lastSyncFirebase.dateValue()) ?? ""
            }
        }
    }
    
    func fetchLatestVersion() {
        statsListener = db.collection("Stats").document("AppInformation").addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            if let latestVersion = data["latestVersion"] as? String {
                self?.latestVersion = latestVersion
            }
            if let updateAppURL = data["updateAppURL"] as? String {
                self?.updateAppURL = updateAppURL
            }
            if let guidedAccessVideo = data["guidedAccessVideo"] as? String {
                self?.guidedAccessVideo = guidedAccessVideo
            }
            if let volunteerVideo = data["volunteerVideo"] as? String {
                self?.volunteerVideo = volunteerVideo
            }
            if let staffVideo = data["staffVideo"] as? String {
                self?.staffVideo = staffVideo
            }
            if let feedbackURL = data["feedbackURL"] as? String {
                self?.feedbackURL = feedbackURL
            }
            if let reportProblemURL = data["reportProblemURL"] as? String {
                self?.reportProblemURL = reportProblemURL
            }
            if let donationURL = data["donationURL"] as? String {
                self?.donationURL = donationURL
            }
            if let animalNotesJotformURL = data["animalNotesJotformURL"] as? String {
                self?.animalNotesJotformURL = animalNotesJotformURL
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
    
    func fetchCatData(completion: @escaping (Bool) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(false)
            return
        }

        fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
            switch result {
            case .success(let id):
                let societyID = id
                self.listenForSocietyLastSyncUpdate(societyID: id)

                self.catListener = self.db.collection("Societies").document(societyID).collection("Cats").addSnapshotListener { [weak self] (querySnapshot, err) in
                    guard let documents = querySnapshot?.documents else {
                        print("No documents")
                        DispatchQueue.main.async {
                            completion(false)
                        }
                        return
                    }

                    let fetchedCats = documents.compactMap { queryDocumentSnapshot in
                        do {
                            let data = queryDocumentSnapshot.data()
                            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                            let animal = try JSONDecoder().decode(Animal.self, from: jsonData)
                            return animal
                        } catch {
                            print("Animal transformation failed: \(error)")
                            return nil
                        }
                    }

                    DispatchQueue.main.async {
                        self?.cats = fetchedCats.filter(self?.filterAnimals ?? { _ in true })
//                        let filteredCats = sortedCats.filter(self?.filterAnimals ?? { _ in true })
                        self?.sortCats()
                        print("Fetched \(self?.cats.count ?? 0) cats")
                        completion(true)
                    }
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    
    
    func fetchDogData(completion: @escaping (Bool) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(false)
            return
        }

        fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
            switch result {
            case .success(let id):
                let societyID = id
                self.listenForSocietyLastSyncUpdate(societyID: id)

                self.dogListener = self.db.collection("Societies").document(societyID).collection("Dogs").addSnapshotListener { [weak self] (querySnapshot, err) in
                    guard let documents = querySnapshot?.documents else {
                        print("No documents")
                        DispatchQueue.main.async {
                            completion(false)
                        }
                        return
                    }

                    let fetchedDogs = documents.compactMap { queryDocumentSnapshot in
                        do {
                            let data = queryDocumentSnapshot.data()
                            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                            let animal = try JSONDecoder().decode(Animal.self, from: jsonData)
                            return animal
                        } catch {
                            print("Animal transformation failed: \(error)")
                            return nil
                        }
                    }

                    DispatchQueue.main.async {
                        self?.dogs = fetchedDogs.filter(self?.filterAnimals ?? { _ in true })
                        self?.sortDogs()
//                        let filteredDogs = self.sortedDogs.filter(self?.filterAnimals ?? { _ in true })
                        print("Fetched \(self?.dogs.count ?? 0) dogs")
                        completion(true)
                    }
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }





    private func filterAnimals(animal: Animal) -> Bool {
        var result = true
        if !showAllAnimals {
            let canPlay = animal.canPlay
            result = canPlay
            print("Animal \(animal.id) - canPlay: \(canPlay), result: \(result)")
        }
        return result
    }


    
    
    func removeListeners() {
        catListener?.remove()
        dogListener?.remove()
        societyListener?.remove()
        statsListener?.remove()
    }
}
