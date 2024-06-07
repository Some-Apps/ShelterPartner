//
//  SettingsViewModel.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/21/23.
//

import FirebaseFirestore
import SwiftUI


class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()
    
    @Published var showAccountUpdated = false
    @Published var showPasswordChanged = false
    @Published var showShareSheet = false
    @Published var fileToShare: URL? = nil
    @Published var isFetchingData = false // New property
    @AppStorage("societyID") var storedSocietyID: String = ""
    
    @Published var reportsDay: String = "Never"
    @Published var reportsEmail: String = ""
    
    @Published var catTags: [String] = []
    @Published var dogTags: [String] = []
    @Published var filterOptions: [String] = []
    @Published var software: String = ""
    @Published var shelter: String = ""
    @Published var mainFilter: String = ""
    @Published var syncFrequency: String = ""
    @Published var apiKey: String = ""
    
    var listener: ListenerRegistration?
    
    init() {
        setupListener()
    }
    
    func addTag(tag: String, species: AnimalType) {
        let db = Firestore.firestore()
        let societyRef = db.collection("Societies").document(storedSocietyID)
        
        // Use FieldValue.arrayUnion to add the tag
        switch species {
        case .Cat:
            societyRef.updateData([
                "catTags": FieldValue.arrayUnion([tag])
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    print(self.storedSocietyID)
                    print(tag)
                }
            }
        case .Dog:
            societyRef.updateData([
                "dogTags": FieldValue.arrayUnion([tag])
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    print(self.storedSocietyID)
                    print(tag)
                }
            }
        }
    }

    func deleteTag(at offsets: IndexSet, species: AnimalType) {
        for index in offsets {
            switch species {
            case .Cat:
                let tag = catTags[index]
                Firestore.firestore().collection("Societies").document(storedSocietyID).updateData([
                    "catTags": FieldValue.arrayRemove([tag])
                ])
            case .Dog:
                let tag = dogTags[index]
                Firestore.firestore().collection("Societies").document(storedSocietyID).updateData([
                    "dogTags": FieldValue.arrayRemove([tag])
                ])
            }
            
        }
        
        switch species {
        case .Cat:
            catTags.remove(atOffsets: offsets)
        case .Dog:
            dogTags.remove(atOffsets: offsets)
        }
    }

    
    func moveTag(from source: IndexSet, to destination: Int, species: AnimalType) {
        switch species {
        case .Cat:
            catTags.move(fromOffsets: source, toOffset: destination)
        case .Dog:
            dogTags.move(fromOffsets: source, toOffset: destination)
        }
        updateTagsInFirestore(species: species)
    }
    
    private func updateTagsInFirestore(species: AnimalType) {
        Firestore.firestore().collection("Societies").document(storedSocietyID).updateData([species == .Cat ? "catTags" : "dogTags": species == .Cat ? catTags: dogTags])
    }
    
    func setupListener() {
        guard !storedSocietyID.isEmpty else { return }
        
        listener = Firestore.firestore().collection("Societies").document(storedSocietyID)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching scheduled reports: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let reportsDay = data["reportsDay"] as? String,
                      let reportsEmail = data["reportsEmail"] as? String else {
                    print("Failed to parse scheduled reports.")
                    return
                }

                // Optional fields
                let catTags = data["catTags"] as? [String] ?? []
                let dogTags = data["dogTags"] as? [String] ?? []
                let filterOptions = data["filterOptions"] as? [String] ?? []
                let software = data["software"] as? String ?? ""
                let shelter = data["shelter"] as? String ?? ""
                let mainFilter = data["mainFilter"] as? String ?? ""
                let syncFrequency = data["syncFrequency"] as? String ?? ""
                let apiKey = data["apiKey"] as? String ?? ""

                self?.reportsDay = reportsDay
                self?.reportsEmail = reportsEmail
                self?.catTags = catTags
                self?.dogTags = dogTags
                self?.software = software
                self?.shelter = shelter
                self?.filterOptions = filterOptions
                self?.mainFilter = mainFilter
                self?.syncFrequency = syncFrequency
                self?.apiKey = apiKey
            }
    }


        deinit {
            listener?.remove() // Stop listening to changes when the object is deinitialized
        }
    
    func updateScheduledReports(newDay: String, newEmail: String) {
        Firestore.firestore().collection("Societies").document(storedSocietyID).updateData([
            "reportsDay": newDay,
            "reportsEmail": newEmail
        ])
    }
    
    func updateAccountSettings(shelter: String, software: String, apiKey: String, mainFilter: String) {
        Firestore.firestore().collection("Societies").document(storedSocietyID).updateData([
            "shelter": shelter,
            "software": software,
            "apiKey": apiKey,
            "mainFilter": mainFilter
        ])
    }
}
