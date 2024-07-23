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
    
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    
    @Published var showAccountUpdated = false
    @Published var showPasswordChanged = false
    @Published var showShareSheet = false
    @Published var fileToShare: URL? = nil
    @Published var isFetchingData = false // New property


    func addKey(name: String, key: String) {
        let db = Firestore.firestore()
        let societyRef = db.collection("Societies").document(authViewModel.shelterID)
        
        let newKey = ["key": key, "name": name]
        
        societyRef.updateData([
            "keys": FieldValue.arrayUnion([newKey])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func deleteKey(_ key: APIKey) {
        let db = Firestore.firestore()
        let societyRef = db.collection("Societies").document(authViewModel.shelterID)
            
            societyRef.updateData([
                "keys": FieldValue.arrayRemove([["key": key.key, "name": key.name]])
            ]) { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed")
                    self.authViewModel.apiKeys.removeAll { $0.id == key.id }
                }
            }
        }


    func addItem(title: String, category: String) {
        let db = Firestore.firestore()
        let societyRef = db.collection("Societies").document(authViewModel.shelterID)
        
        societyRef.updateData([
            category: FieldValue.arrayUnion([title])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                print(self.authViewModel.shelterID)
                print(title)
            }
        }
    }
    
    func addTag(tag: String, species: AnimalType) {
        let db = Firestore.firestore()
        let societyRef = db.collection("Societies").document(authViewModel.shelterID)
        
        switch species {
        case .Cat:
            societyRef.updateData([
                "catTags": FieldValue.arrayUnion([tag])
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    print(self.authViewModel.shelterID)
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
                    print(self.authViewModel.shelterID)
                    print(tag)
                }
            }
        }
    }
    
    func deleteReason(at offsets: IndexSet) {
        for index in offsets {
            let reason = authViewModel.earlyReasons[index]
            Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([
                "earlyReasons": FieldValue.arrayRemove([reason])
            ])
        }
        authViewModel.earlyReasons.remove(atOffsets: offsets)
    }
    
    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let type = authViewModel.letOutTypes[index]
            Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([
                "letOutTypes": FieldValue.arrayRemove([type])
            ])
        }
        authViewModel.letOutTypes.remove(atOffsets: offsets)
    }
    
    func moveReason(from source: IndexSet, to destination: Int) {
        authViewModel.earlyReasons.move(fromOffsets: source, toOffset: destination)
        Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData(["earlyReasons": authViewModel.earlyReasons])
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
        authViewModel.letOutTypes.move(fromOffsets: source, toOffset: destination)
        Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData(["letOutTypes": authViewModel.letOutTypes])
    }

    func deleteTag(at offsets: IndexSet, species: AnimalType) {
        for index in offsets {
            switch species {
            case .Cat:
                let tag = authViewModel.catTags[index]
                Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([
                    "catTags": FieldValue.arrayRemove([tag])
                ])
            case .Dog:
                let tag = authViewModel.dogTags[index]
                Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([
                    "dogTags": FieldValue.arrayRemove([tag])
                ])
            }
            
        }
        
        switch species {
        case .Cat:
            authViewModel.catTags.remove(atOffsets: offsets)
        case .Dog:
            authViewModel.dogTags.remove(atOffsets: offsets)
        }
    }

    
    func moveTag(from source: IndexSet, to destination: Int, species: AnimalType) {
        switch species {
        case .Cat:
            authViewModel.catTags.move(fromOffsets: source, toOffset: destination)
        case .Dog:
            authViewModel.dogTags.move(fromOffsets: source, toOffset: destination)
        }
        updateTagsInFirestore(species: species)
    }
    
    private func updateTagsInFirestore(species: AnimalType) {
        Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([species == .Cat ? "catTags" : "dogTags": species == .Cat ? authViewModel.catTags: authViewModel.dogTags])
    }

    
//    func setupListener() {
//        guard !authViewModel.shelterID.isEmpty else { return }
//        
//        listener = Firestore.firestore().collection("Societies").document(authViewModel.shelterID)
//            .addSnapshotListener { [weak self] snapshot, error in
//                if let error = error {
//                    print("Error fetching scheduled reports: \(error)")
//                    return
//                }
//                
//                guard let data = snapshot?.data() else {
//                    print("No data found for document")
//                    return
//                }
//                
//                self?.updateProperties(with: data)
//            }
//    }

//    private func updateProperties(with data: [String: Any]) {
//        DispatchQueue.main.async {
//            self.reportsDay = data["reportsDay"] as? String ?? ""
//            self.reportsEmail = data["reportsEmail"] as? String ?? ""
//            self.earlyReasons = data["earlyReasons"] as? [String] ?? []
//            self.catTags = data["catTags"] as? [String] ?? []
//            self.dogTags = data["dogTags"] as? [String] ?? []
//            self.software = data["software"] as? String ?? ""
//            self.shelter = data["shelter"] as? String ?? ""
//            self.mainFilter = data["mainFilter"] as? String ?? ""
//            self.syncFrequency = data["syncFrequency"] as? String ?? ""
//            self.apiKey = data["apiKey"] as? String ?? ""
//            self.secondarySortOptions = data["secondarySortOptions"] as? [String] ?? []
//            self.groupOptions = data["groupOptions"] as? [String] ?? []
//        }
//    }



    func updateScheduledReports(newDay: String, newEmail: String) {
        Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([
            "reportsDay": newDay,
            "reportsEmail": newEmail
        ])
    }
    
    func updateAccountSettings(shelter: String, software: String, apiKey: String, mainFilter: String) {
        Firestore.firestore().collection("Societies").document(authViewModel.shelterID).updateData([
            "shelter": shelter,
            "software": software,
            "apiKey": apiKey,
            "mainFilter": mainFilter
        ])
    }
}
