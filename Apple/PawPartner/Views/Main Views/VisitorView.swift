import SSToastMessage
import FirebaseAuth
import AlertToast
import SwiftUI
import Kingfisher
import WebKit
import UIKit

struct VisitorView: View {
    // MARK: -Properties
    @StateObject var cardViewModel = CardViewModel()

    @ObservedObject var authViewModel = AuthenticationViewModel.shared
    @ObservedObject var viewModel = AnimalViewModel.shared

    @AppStorage("latestVersion") var latestVersion: String = ""
    @AppStorage("updateAppURL") var updateAppURL: String = ""
    @AppStorage("animalType") var animalType = AnimalType.Cat
    @AppStorage("societyID") var storedSocietyID: String = ""
    @AppStorage("mode") var mode = "volunteer"
    @AppStorage("feedbackURL") var feedbackURL: String = ""
    @AppStorage("reportProblemURL") var reportProblemURL: String = ""

    
    @State private var screenWidth: CGFloat = 500
    @State private var isImageLoaded = false
    @State private var showingPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var showIncorrectPassword = false
    @State private var showLoading = false
    @State private var showingFeedbackForm = false
    @State private var showingReportForm = false
    @State private var showFullScreenImage = false
    @State private var selectedImageIndex = 0

    
    let width: CGFloat = 200
    let height: CGFloat = 200
    let columns = [
        GridItem(.adaptive(minimum: 200))
    ]


    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
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
    
    


    // MARK: -Body
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        showingFeedbackForm = true
                    } label: {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                            Text("Give Feedback")
                        }
                    }
                    .sheet(isPresented: $showingFeedbackForm) {
                        if let feedbackURL = URL(string: "\(feedbackURL)/?societyid=\(storedSocietyID)") {
                            WebView(url: feedbackURL)
                        }
                    }
                    Spacer()
                    if mode != "volunteerAdmin" && mode != "visitorAdmin" {
                        Button("Switch To Admin") {
                            showingPasswordPrompt = true
                        }
                        .sheet(isPresented: $showingPasswordPrompt) {
                            PasswordPromptView(isShowing: $showingPasswordPrompt, passwordInput: $passwordInput, showIncorrectPassword: $showIncorrectPassword) {
                                authViewModel.verifyPassword(password: passwordInput) { isCorrect in
                                    if isCorrect {
                                        // The password is correct. Enable the feature here.
                                        //                                        volunteerMode.toggle()
                                        mode = "volunteerAdmin"
                                    } else {
                                        // The password is incorrect. Show an error message.
                                        print("Incorrect Password")
                                        showIncorrectPassword.toggle()
                                        passwordInput = ""
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                    }
                    if mode == "volunteerAdmin" || mode == "visitorAdmin" {
                        Button("Turn Off Admin") {
                            mode = "volunteer"
                        }
                        Spacer()
                    }
                   
                        Button("Switch To Volunteer") {
                            if mode == "visitorAdmin" {
                                mode = "volunteerAdmin"
                            } else {
                                mode = "volunteer"
                            }
                        }
                        Spacer()
                   
                    
                    Button {
                        showingReportForm = true
                    } label: {
                        HStack {
                            Text("Report Problem")
                            Image(systemName: "exclamationmark.bubble.fill")
                        }
                    }
                    .sheet(isPresented: $showingReportForm) {
                        if let reportProblemURL = URL(string: "\(reportProblemURL)/?societyid=\(storedSocietyID)") {
                            WebView(url: reportProblemURL)
                            
                        }
                    }
                }
                .padding([.horizontal, .top])
                .font(UIDevice.current.userInterfaceIdiom == .phone ? .caption : .body)

//                    if mode == "visitor" {
//                        Button("Switch To Admin") {
//                            showingPasswordPrompt = true
//                        }
//                        .sheet(isPresented: $showingPasswordPrompt) {
//                            PasswordPromptView(isShowing: $showingPasswordPrompt, passwordInput: $passwordInput, showIncorrectPassword: $showIncorrectPassword) {
//                                authViewModel.verifyPassword(password: passwordInput) { isCorrect in
//                                    if isCorrect {
//                                        // The password is correct. Enable the feature here.
//                                        mode = "admin"
//                                    } else {
//                                        // The password is incorrect. Show an error message.
//                                        print("Incorrect Password")
//                                        showIncorrectPassword.toggle()
//                                        passwordInput = ""
//                                    }
//                                }
//                            }
//                        }
//                    }
                    Picker("Animal Type", selection: $animalType) {
                        ForEach(AnimalType.allCases, id: \.self) { animalType in
                            Text("\(animalType.rawValue)s").tag(animalType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])
                
                
                ScrollView {
                    switch animalType {
                    case .Dog:
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.sortedVisitorDogs) { dog in
                                if dog.canPlay {
                                    NavigationLink(destination: VisitorDetailView(animal: dog)) {
                                        VStack {
                                            VisitorImage(animal: dog)
                                            
                                            Text(dog.name)
                                                .foregroundStyle(.black)
                                                .bold()
                                                .font(.title2)
                                        }
                                        .padding(.horizontal)

                                    }
                                }
                                
                                             
                            }
                        }
                        .padding(.horizontal)
                        
                    case .Cat:
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.sortedVisitorCats) { cat in
                                if cat.canPlay {
                                    NavigationLink(destination: VisitorDetailView(animal: cat)) {
                                        VStack {
                                            VisitorImage(animal: cat)
                                            
                                            Text(cat.name)
                                                .foregroundStyle(.black)
                                                .bold()
                                                .font(.title2)
                                        }
                                        .padding(.horizontal)

                                    }

                                }
                            }
                        }
                        .padding(.horizontal)

                    }
                    
                    
                    
                    HStack {
                        if latestVersion != "\(appVersion)" {
                            VStack {
                                Text("Your app is not up to date. Please update when convenient.")
                                Button(action: {
                                    if let url = URL(string: updateAppURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {                                    Label("Update", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(.thinMaterial))
                            .background(RoundedRectangle(cornerRadius: 20).fill(.customOrange))
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .toast(isPresenting: $showLoading) {
            AlertToast(displayMode: .alert, type: .loading)
        }
        .onAppear {
            if storedSocietyID == "" && Auth.auth().currentUser?.uid != nil {
                viewModel.fetchSocietyID(forUser: Auth.auth().currentUser!.uid) { (result) in
                    switch result {
                    case .success(let id):
                        storedSocietyID = id
                        viewModel.listenForSocietyLastSyncUpdate(societyID: id)
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            viewModel.fetchCatData() { _ in }
            viewModel.fetchDogData() { _ in }
            viewModel.fetchLatestVersion()
            if storedSocietyID.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                viewModel.postAppVersion(societyID: storedSocietyID, installedVersion: "\(appVersion) (\(buildNumber))")
            }
        }

        .toast(isPresenting: $showIncorrectPassword) {
            AlertToast(type: .error(.red), title: "Incorrect Password")
        }
    }
    // MARK: -Methods
}


struct VisitorImage: View {
    let animal: Animal
    @AppStorage("lastSync") var lastSync: String = ""
    @State private var isImageCached: Bool = false

    var imageURL: URL? {
        if let photo = animal.allPhotos.first {
            return URL(string: photo)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            Image(systemName: "photo.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
                .frame(width: 150, height: 150)
            VStack {
                        KFImage(imageURL)
//                            .placeholder {
//                                Image(systemName: "photo.circle.fill")
//                                    .resizable()
//                                    .foregroundStyle(.secondary)
//                                    .frame(width: 150, height: 150)
//                            }
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))
                                          |> RoundCornerImageProcessor(cornerRadius: 20))
                            .scaleFactor(UIScreen.main.scale)
                            .cacheOriginalImage()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding([.horizontal, .top])
                            
                    }
            
 
            
        }
        
    }

}



#Preview {
    VisitorView()
}

