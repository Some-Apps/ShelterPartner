//
//  CardViewModel.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/23/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class CardViewModel: ObservableObject {
    @ObservedObject var animalViewModel = AnimalViewModel.shared
    @ObservedObject var authViewModel = AuthenticationViewModel.shared
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("minimumDuration") var minimumDuration = 5
    @AppStorage("requireName") var requireName = false
    @AppStorage("createLogsAlways") var createLogsAlways = false
    @AppStorage("automaticPutBackIgnoreVisit") var automaticPutBackIgnoreVisit = true

    @Published var shortReason = ""
    @Published var letOutType = ""

    // Test if this works
    func takeOut(animal: Animal) {
        let db = Firestore.firestore()
        db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
            "startTime": Date().timeIntervalSince1970,
            "inCage": false
        ]){ err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated: Animal taken out")
            }
        }
    }
    
    func putBack(animal: Animal) {
        let db = Firestore.firestore()
        db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
            "inCage": true
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                
                let components = Calendar.current.dateComponents([.minute], from: Date(timeIntervalSince1970: animal.startTime), to: Date())
                if components.minute ?? 0 >= self.minimumDuration {
                    self.createLog(for: animal)
                    self.animalViewModel.animal = animal
                    self.animalViewModel.showLogCreated.toggle()
                } else {
                    if self.createLogsAlways {
                        self.createLog(for: animal)
                        self.animalViewModel.animal = animal
                        self.animalViewModel.showLogCreated.toggle()
                    } else {
                        self.animalViewModel.showLogTooShort.toggle()
                    }
                }
            }
        }
    }
    
    func bulkPutBack(animals: [Animal]) {
        let db = Firestore.firestore()
        for animal in animals {
            db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                "inCage": true
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    
                    let components = Calendar.current.dateComponents([.minute], from: Date(timeIntervalSince1970: animal.startTime), to: Date())
                    if components.minute ?? 0 >= self.minimumDuration {
                        self.createLog(for: animal)
                        self.animalViewModel.animal = animal
                    }
                }
            }
        }
        
    }
    
    func silentPutBack(animal: Animal) {
        let db = Firestore.firestore()
        db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
            "inCage": true
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                
                if !self.automaticPutBackIgnoreVisit {
                    let components = Calendar.current.dateComponents([.minute], from: Date(timeIntervalSince1970: animal.startTime), to: Date())
                    self.createSilentLog(for: animal)
                    if components.minute ?? 0 >= 5 {
                        self.createLog(for: animal)
                    }
                }
                
            }
        }
    }
    
    func createSilentLog(for animal: Animal) {
        let db = Firestore.firestore()
        
        // Fetch the document
        db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).getDocument { (document, error) in
            if let document = document, document.exists, let data = document.data() {
                // Retrieve startTime from the fetched document data
                if let startTime = data["startTime"] as? Double {
                    print(startTime)
                    print(Date())
                    
                    // Create a new log
                    let id = UUID().uuidString
                    let newLog = Log(id: id, startTime: startTime, endTime: startTime + 3600)
                    
                    // Convert newLog to a dictionary
                    let logDict: [String: Any] = [
                        "id": newLog.id,
                        "startTime": newLog.startTime,
                        "endTime": newLog.endTime
                    ]
                    
                    // Add newLog to the logs array in the specified animal's document
                    db.collection("Societies").document(self.authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                        "logs": FieldValue.arrayUnion([logDict])
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                } else {
                    print("Error: StartTime not found in document.")
                }
            } else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    
    func createLog(for animal: Animal) {
        print("create log has been called")
        let db = Firestore.firestore()
        
        // Fetch the document
        db.collection("Societies").document(authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).getDocument { (document, error) in
            if let document = document, document.exists, let data = document.data() {
                // Retrieve startTime from the fetched document data
                if let startTime = data["startTime"] as? Double {
//                    print(startTime)
//                    print(Date())
                    var lastVolunteer = ""
                    lastVolunteer = data["lastVolunteer"] as? String ?? ""
                    var lastLetOutType = data["lastLetOutType"] as? String ?? ""
                    lastLetOutType = data["lastLetOutType"] as? String ?? ""
                    // Create a new log
                    let id = UUID().uuidString
                    let newLog = Log(id: id, startTime: startTime, endTime: Date().timeIntervalSince1970, user: lastVolunteer, shortReason: self.shortReason, letOutType: lastLetOutType)
                    
                    // Convert newLog to a dictionary
                    let logDict: [String: Any] = [
                        "id": newLog.id,
                        "startTime": newLog.startTime,
                        "endTime": newLog.endTime,
                        "user": newLog.user ?? "",
                        "shortReason": newLog.shortReason ?? "",
                        "letOutType": newLog.letOutType ?? ""
                    ]
                    db.collection("Societies").document(self.authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                        "lastVolunteer": "",
                        "lastLetOutType": ""
                    ]){ err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                    
                    // Add newLog to the logs array in the specified animal's document
                    db.collection("Societies").document(self.authViewModel.shelterID).collection("\(animal.animalType.rawValue)s").document(animal.id).updateData([
                        "logs": FieldValue.arrayUnion([logDict])
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                } else {
                    print("Error: StartTime not found in document.")
                }
            } else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
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
    
}
