//
//  ThankYouView.swift
//  HumaneSociety
//
//  Created by Jared Jones on 12/2/23.
//

import SwiftUI
import Kingfisher

struct ThankYouView: View {
    @ObservedObject var viewModel = AnimalViewModel.shared
    
    @State private var showAddNote = false
    @State private var toastAddNote = false
    @State private var imageLoaded = false
    @State private var isImageLoaded = false
    @AppStorage("customFormURL") var customFormURL = ""
    @AppStorage("isCustomFormOn") var isCustomFormOn = false
    @AppStorage("linkType") var linkType = "QR Code"

    let animal: Animal
    
    @AppStorage("lastSync") var lastSync: String = ""
    @AppStorage("societyID") var storedSocietyID: String = ""
    
    @State private var showCustomQR = false
    @State private var showCustomLink = false

//    var imageUrl: URL? {
//        if let safeAnimalName = animal.id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
//           var urlComponents = URLComponents(string: "https://firebasestorage.googleapis.com/v0/b/humanesociety-21855.appspot.com/o/\(storedSocietyID)%2F\(safeAnimalName).jpeg?alt=media") {
//            // Append a unique query parameter to the URL
//            let queryItem = URLQueryItem(name: "v", value: lastSync)
//            let mediaItem = URLQueryItem(name: "alt", value: "media")
//            urlComponents.queryItems = [mediaItem, queryItem]
//
//            let url = urlComponents.url
//            return url
//        }
//        return nil
//    }
    
    var body: some View {
        ZStack {
            VStack {
                if let url = animal.photos.first?.url {
                    KFImage(URL(string: url))
                        .resizable()
                        .onSuccess { _ in imageLoaded = true } // Update state when the image is loaded
                        .placeholder {
                            Image(systemName: "photo") // Placeholder image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .opacity(imageLoaded ? 0 : 1) // Hide placeholder when image is loaded
                        }
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .opacity(imageLoaded ? 1 : 0) // Show the image only when it's loaded
                }
                Text("Thank You!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .padding()
                VStack {
                    HStack {
                        Spacer()
                        Button("Close") {
                            viewModel.showLogCreated.toggle()
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .font(.title)
                        .italic()
                        Spacer()
                        Button {
                            viewModel.showLogCreated.toggle()
                            showAddNote.toggle()
                        } label: {
                            Label("Add Note", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        .font(.title)
                        .bold()
                        Spacer()
                    }
                    if isCustomFormOn {
                            Button {
                                if linkType == "QR Code" {
                                    showCustomQR.toggle()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                        showCustomQR = false
                                    }
                                } else {
                                    showCustomLink.toggle()
                                }
                                
                            } label: {
                                Label("Custom Form", systemImage: linkType == "QR Code" ? "qrcode" : "book.pages")
                            }
                            
                            .buttonStyle(.bordered)
                            .tint(.green)
                            .font(.title)
                            .bold()
                    }
                }
            }
            .padding()
            .frame(maxWidth: 350)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(radius: 8)
            )
            .sheet(isPresented: $showAddNote) {
                AddNoteView(animal: viewModel.animal)
            }
            .sheet(isPresented: $showCustomQR) {
                CustomQRCodeView(url: customFormURL)
            }
            .sheet(isPresented: $showCustomLink) {
                WebView(url: URL(string: customFormURL) ?? URL(string: "https://pawpartner.app")!)
            }
        }
    }
    
    func loadImage(completion: @escaping (Bool) -> Void) {
        guard let urlString = animal.photos.first?.url else {
            completion(false)
            return
        }
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                completion(data != nil)
            }
        }
        task.resume()
    }

}

#Preview {
    ThankYouView(animal: Animal.dummyAnimal)
}
