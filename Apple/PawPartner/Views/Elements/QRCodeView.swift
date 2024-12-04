import SwiftUI
import CoreImage.CIFilterBuiltins
import Firebase

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct QRCodeView: View {
    var timestamp = Date().timeIntervalSince1970.description
    @AppStorage("animalNotesJotformURL") var animalNotesJotformURL: String = ""
    var animal: Animal
    
    @State private var societyID: String? = nil
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if let societyID = societyID {
                Image(uiImage: generateQRCode(from: "\(animalNotesJotformURL)?societyid=\(societyID)&animalid=\(animal.id)&animal=\(animal.name)&species=\(animal.animalType.rawValue)s&submissionid=\(UUID().uuidString)&timestamp=\(timestamp)"))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 500)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            Task {
                await fetchSocietyID()
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    func fetchSocietyID() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        do {
            let fetchedSocietyID = try await fetchSocietyID(forUser: userID)
            societyID = fetchedSocietyID
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchSocietyID(forUser userID: String) async throws -> String {
        let db = Firestore.firestore()

        return try await withCheckedThrowingContinuation { continuation in
            db.collection("Users").document(userID).getDocument { (document, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    if let document = document, document.exists, let data = document.data(),
                       let societyID = data["societyID"] as? String {
                        continuation.resume(returning: societyID)
                    } else {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "SocietyID not found"])
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}


struct CustomQRCodeView: View {
    var url: String
    
    var body: some View {
        Image(uiImage: generateQRCode(from: url))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 500)
    }

    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

#Preview {
    QRCodeView(animal: Animal.dummyAnimal)
}
