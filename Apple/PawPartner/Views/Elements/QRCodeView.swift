import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    var timestamp = Date().timeIntervalSince1970.description
    @AppStorage("societyID") var societyID = ""
    @AppStorage("animalNotesJotformURL") var animalNotesJotformURL: String = ""
    var animal: Animal
    
    var body: some View {
        Image(uiImage: generateQRCode(from: "\(animalNotesJotformURL)?societyid=\(societyID)&animalid=\(animal.id)&animal=\(animal.name)&species=\(animal.animalType.rawValue)s&submissionid=\(UUID().uuidString)&timestamp=\(timestamp)"))
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
