//
//  AuthenticationViewModel.swift
//  HumaneSociety
//
//  Created by Jared Jones on 5/27/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI
import FirebaseAuth

class AuthenticationViewModel: ObservableObject {
    static let shared = AuthenticationViewModel()
    
    @Published var isSignedIn = false
    @Published var showLoginSuccess = false
    @Published var signUpForm = ""
    @AppStorage("volunteerVideo") var volunteerVideo = ""
    @AppStorage("staffVideo") var staffVideo = ""
    @AppStorage("guidedAccessVideo") var guidedAccessVideo = ""
    
    var handle: AuthStateDidChangeListenerHandle?
    var signUpListener: ListenerRegistration?

    init() {
        isSignedIn = Auth.auth().currentUser != nil
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                print("User \(user.uid) signed in")
                self?.isSignedIn = true
            } else {
                print("User signed out")
                self?.isSignedIn = false
            }
        }
    }
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
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
            if let signUpForm = data["signUpForm"] as? String {
                self?.signUpForm = signUpForm
            }
            if let volunteerVideo = data["volunteerVideo"] as? String {
                self?.volunteerVideo = volunteerVideo
            }
            if let staffVideo = data["staffVideo"] as? String {
                self?.staffVideo = staffVideo
            }
            if let guidedAccessVideo = data["guidedAccessVideo"] as? String {
                self?.guidedAccessVideo = guidedAccessVideo
            }
        }
    }
    
    func removeListeners() {
        signUpListener?.remove()
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
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


    func updatePassword(oldPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }

        // Create credential with existing user email and provided old password
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        
        // Reauthenticate user
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                print("Error in reauthentication: \(error.localizedDescription)")
                // Handle error and show an alert to the user
                return
            }
            
            // If reauthentication successful, proceed with password update
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    print("Error updating password: \(error.localizedDescription)")
                    // Handle error and show an alert to the user
                } else {
                    print("Password updated successfully!")
                    // Show some confirmation message to the user
                }
            }
        }
    }
}
