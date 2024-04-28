//
//  AnimalsViewModel.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/20/23.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Foundation

class AnimalViewModel: ObservableObject {
    static let shared = AnimalViewModel()
    
    @Published var sortedDogs: [Animal] = []
    @Published var sortedCats: [Animal] = []
    
    @Published var sortedVisitorDogs: [Animal] = []
    @Published var sortedVisitorCats: [Animal] = []
    
    @Published var showLogTooShort = false
    @Published var showLogCreated = false
    @Published var showAggressionRating = false
    @Published var showAnimalAlert = false
    @Published var showQRCode = false
    @Published var cats = [Animal]()
    @Published var dogs = [Animal]()
//    @Published var lastSync: Date?
    @Published var animal: Animal = Animal.dummyAnimal
    @Published var toastAddNote = false
    
    var catListener: ListenerRegistration?
    var dogListener: ListenerRegistration?
    var societyListener: ListenerRegistration?
    var statsListener: ListenerRegistration?
    
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
    @AppStorage("societyID") var storedSocietyID: String = ""
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
//                if cat1.prioritize, let log = cat1.logs.last, log.durationInMinutes > cat1.prioritizeMinutes {
//                    return true
//                }
//                if cat2.prioritize, let log = cat2.logs.last, log.durationInMinutes > cat2.prioritizeMinutes {
//                    return false
//                }
                return cat1.logs.last?.endTime ?? 0 < cat2.logs.last?.endTime ?? 0
                
            case .playtime24Hours:
//                if cat1.prioritize, let log = cat1.logs.last, log.durationInMinutes > cat1.prioritizeMinutes {
//                    return true
//                }
//                if cat2.prioritize, let log = cat2.logs.last, log.durationInMinutes > cat2.prioritizeMinutes {
//                    return false
//                }
                return cat1.playtimeLast24Hours < cat2.playtimeLast24Hours
            case .playtime7Days:
//                if cat1.prioritize, let log = cat1.logs.last, log.durationInMinutes > cat1.prioritizeMinutes {
//                    return true
//                }
//                if cat2.prioritize, let log = cat2.logs.last, log.durationInMinutes > cat2.prioritizeMinutes {
//                    return false
//                }
                return cat1.playtimeLast7Days < cat2.playtimeLast7Days
            case .playtime30Days:
//                if cat1.prioritize, let log = cat1.logs.last, log.durationInMinutes > cat1.prioritizeMinutes {
//                    return true
//                }
//                if cat2.prioritize, let log = cat2.logs.last, log.durationInMinutes > cat2.prioritizeMinutes {
//                    return false
//                }
                return cat1.playtimeLast30Days < cat2.playtimeLast30Days
            case .playtime90Days:
//                if cat1.prioritize, let log = cat1.logs.last, log.durationInMinutes > cat1.prioritizeMinutes {
//                    return true
//                }
//                if cat2.prioritize, let log = cat2.logs.last, log.durationInMinutes > cat2.prioritizeMinutes {
//                    return false
//                }
                return cat1.playtimeLast90Days < cat2.playtimeLast90Days
            }
        })
        
        sortedVisitorCats = cats.sorted(by: { cat1, cat2 in
            return cat1.logs.first?.startTime ?? 0 < cat2.logs.first?.startTime ?? 0
        })
    }
    
    func sortDogs() {
        sortedDogs = dogs.sorted(by: { dog1, dog2 in
            switch sortBy {
            case .lastLetOut:
//                if dog1.prioritize, let log = dog1.logs.last, log.durationInMinutes > dog1.prioritizeMinutes {
//                    return true
//                }
//                if dog2.prioritize, let log = dog2.logs.last, log.durationInMinutes > dog2.prioritizeMinutes {
//                    return false
//                }
                return dog1.logs.last?.endTime ?? 0 < dog2.logs.last?.endTime ?? 0
                
            case .playtime24Hours:
//                if dog1.prioritize, let log = dog1.logs.last, log.durationInMinutes > dog1.prioritizeMinutes {
//                    return true
//                }
//                if dog2.prioritize, let log = dog2.logs.last, log.durationInMinutes > dog2.prioritizeMinutes {
//                    return false
//                }
                return dog1.playtimeLast24Hours < dog2.playtimeLast24Hours
            case .playtime7Days:
//                if dog1.prioritize, let log = dog1.logs.last, log.durationInMinutes > dog1.prioritizeMinutes {
//                    return true
//                }
//                if dog2.prioritize, let log = dog2.logs.last, log.durationInMinutes > dog2.prioritizeMinutes {
//                    return false
//                }
                return dog1.playtimeLast7Days < dog2.playtimeLast7Days
            case .playtime30Days:
//                if dog1.prioritize, let log = dog1.logs.last, log.durationInMinutes > dog1.prioritizeMinutes {
//                    return true
//                }
//                if dog2.prioritize, let log = dog2.logs.last, log.durationInMinutes > dog2.prioritizeMinutes {
//                    return false
//                }
                return dog1.playtimeLast30Days < dog2.playtimeLast30Days
            case .playtime90Days:
//                if dog1.prioritize, let log = dog1.logs.last, log.durationInMinutes > dog1.prioritizeMinutes {
//                    return true
//                }
//                if dog2.prioritize, let log = dog2.logs.last, log.durationInMinutes > dog2.prioritizeMinutes {
//                    return false
//                }
                return dog1.playtimeLast90Days < dog2.playtimeLast90Days
            }
        })
        
        sortedVisitorDogs = dogs.sorted(by: { dog1, dog2 in
            return dog1.logs.first?.startTime ?? 0 < dog2.logs.first?.startTime ?? 0
        })
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
    
    
    func fetchCatData() {
        guard Auth.auth().currentUser != nil else { return }
        
        fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
            switch result {
            case .success(let id):
                let societyID = id
                self.listenForSocietyLastSyncUpdate(societyID: id)

                self.catListener = self.db.collection("Societies").document(societyID).collection("Cats").addSnapshotListener { [weak self] (querySnapshot, err) in
                    guard let documents = querySnapshot?.documents else {
                        print("No documents")
                        return
                    }

                    self?.cats = documents.compactMap { queryDocumentSnapshot in
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
                    self!.sortCats()
                }
                print(id)
            case .failure(let error):
                print(error)
            }
        }
        
        
    }
    


    func fetchDogData() {
        guard Auth.auth().currentUser != nil else { return }
        
        fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
            switch result {
            case .success(let id):
                let societyID = id
                self.listenForSocietyLastSyncUpdate(societyID: id)

                self.dogListener = self.db.collection("Societies").document(societyID).collection("Dogs").addSnapshotListener { [weak self] (querySnapshot, err) in
                    guard let documents = querySnapshot?.documents else {
                        print("No documents")
                        return
                    }

                    self?.dogs = documents.compactMap { queryDocumentSnapshot in
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
                    self?.sortDogs()
                }
                print(id)
            case .failure(let error):
                print(error)
            }
        }
       
    }
    
    func changeAggressionRating(newRating: Int) {
        print(newRating)
        db.collection("Societies").document(storedSocietyID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
            "aggressionRating": newRating
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    
    
    func removeListeners() {
        catListener?.remove()
        dogListener?.remove()
        societyListener?.remove()
        statsListener?.remove()
    }

    
}
