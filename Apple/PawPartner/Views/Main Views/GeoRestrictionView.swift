import SwiftUI
import Firebase

struct GeoRestrictionView: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var locationManager = LocationManager()

    var body: some View {
        VStack {
            if locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways {
                Text("Location services are not enabled. Please enable location tracking to use the app.")
                    .multilineTextAlignment(.center)
                    .padding()

                Button("Open Location Settings") {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        openURL(appSettings)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Text("This account is geo-restricted. To use the app, you will need to be at the animal shelter.")
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Sign Out") {
                    try? Auth.auth().signOut()
                }
            }
        }
        .padding()
    }
}


#Preview {
    GeoRestrictionView()
}
