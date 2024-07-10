//
//  FeedbackView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 7/29/23.
//

import AlertToast
import FirebaseFirestore
import SwiftUI

struct FeedbackView: View {
    @State private var feedback = ""
    @FocusState private var isFocused: Bool
    @State private var showSuccess = false
//    @AppStorage("societyID") var storedSocietyID: String = ""
    
    @StateObject var viewModel = ViewFeedbackViewModel()
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    private var sortedFeedback: [Feedback] {
        viewModel.feedback.sorted(by: { $1.id < $0.id })
    }
    
    var body: some View {
            Form {
                Section {
                    TextEditor(text: $feedback)
                        .focused($isFocused)
                    //                       .onAppear { isFocused = true }
                        .onTapGesture {
                            isFocused = false
                        }
                    Button("Submit") {
                        giveFeedback(feedback: feedback) { result in
                            switch result {
                            case .success:
                                feedback = ""
                                showSuccess.toggle()
                            case .failure:
                                feedback = ""
                            }
                        }
                    }
                    .disabled(feedback == "")
                }
                
                
                Section {
                    ForEach(sortedFeedback, id: \.id) { feedbackItem in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(feedbackItem.feedback)
                                .bold()
                            Text(feedbackItem.developerResponse)
                                .italic()
                                .fontWeight(.light)
                        }
                    }
                    .onDelete(perform: deleteFeedback)
                }
                
                
            }
            
            
            

                
            
            .toolbar {
                ToolbarItem {
                    EditButton()
                }
            }
            .onAppear {
                viewModel.fetchFeedback()
            }
            .navigationTitle("Feedback")
            .toast(isPresenting: $showSuccess) {
                AlertToast(displayMode: .hud, type: .complete(.green), title: "Feedback Sent!")
            }
            
            
            
        
    }
    
    func deleteFeedback(at offsets: IndexSet) {
        offsets.lazy.map { sortedFeedback[$0].id }.forEach { id in
            let db = Firestore.firestore()

            db.collection("Feedback").document(String(id)).delete { error in
                if let error = error {
                    print("Error deleting feedback item: \(error.localizedDescription)")
                } else {
                    print("Feedback item successfully deleted")
                    if let index = viewModel.feedback.firstIndex(where: { $0.id == id }) {
                        viewModel.feedback.remove(at: index)
                    }
                }
            }
        }
    }
    
    func giveFeedback(feedback: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Get a reference to the Firestore database
        let db = Firestore.firestore()
        
        // Create a reference to the "feedback" collection
        let feedbackRef = db.collection("Feedback")
        
        // Generate the document ID as epoch seconds
        let epochSeconds = Int(Date().timeIntervalSince1970)
        let documentId = "\(epochSeconds)"
        
        // Create a new document with the provided data and the specified document ID
        let newFeedbackRef = feedbackRef.document(documentId)
        newFeedbackRef.setData([
            "societyID": authViewModel.shelterID,
            "feedback": feedback,
            "developerResponse": ""
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completion(.failure(error))
            } else {
                print("Document added with ID: \(documentId)")
                completion(.success(documentId))
            }
        }
    }
}


extension DateFormatter {
    static let feedbackDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}


class ViewFeedbackViewModel: ObservableObject {
    @Published var feedback: [Feedback] = []
//    @AppStorage("societyID") var storedSocietyID: String = ""
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    private var feedbackListenerRegistration: ListenerRegistration?

    func fetchFeedback() {
        let feedbackRef = Firestore.firestore().collection("Feedback")
        
        self.feedbackListenerRegistration?.remove()
        
        self.feedbackListenerRegistration = feedbackRef
            .whereField("societyID", isEqualTo: authViewModel.shelterID)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching feedback: \(error)")
                } else {
                    let feedbackItems = querySnapshot?.documents.compactMap { document -> Feedback? in
                        let data = document.data()
                        guard let feedback = data["feedback"] as? String,
                              let developerResponse = data["developerResponse"] as? String else {
                            return nil
                        }
                        return Feedback(id: document.documentID, type: "Feedback", feedback: feedback, developerResponse: developerResponse)
                    } ?? []
                    self.feedback = feedbackItems
                }
            }
    }
}

struct Feedback: Identifiable, Hashable {
    var id: String
    var type: String
    var feedback: String
    var developerResponse: String
}
