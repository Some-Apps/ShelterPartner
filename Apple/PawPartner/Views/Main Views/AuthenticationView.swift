import FirebaseAuth
import SwiftUI
import CoreLocation
import FirebaseFirestore

struct AuthenticationView: View {
    @ObservedObject var viewModel = AuthenticationViewModel.shared
    @AppStorage("adminMode") var adminMode = true
    @ObservedObject var locationManager = LocationManager()

    var body: some View {
        if viewModel.isSignedIn {
            switch viewModel.accountType {
            case "admin":
                if !adminMode {
                    TabView {
                        AnimalView()
                            .tabItem {
                                Label("Volunteer", systemImage: "pawprint.fill")
                            }
                        VisitorView()
                            .tabItem {
                                Label("Visitor", systemImage: "person.2.circle.fill")
                            }
                    }
                    .onAppear {
                        print("Admin")
                        print(viewModel.shelterID)
                        print(viewModel.accountType)
                    }
                } else {
                    TabView {
                        AnimalView()
                            .tabItem {
                                Label("Volunteer", systemImage: "pawprint.fill")
                            }
                        VisitorView()
                            .tabItem {
                                Label("Visitor", systemImage: "person.2.circle.fill")
                            }
                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                    }
                    .onAppear {
                        print("Admin")
                        print(viewModel.shelterID)
                        print(viewModel.accountType)
                    }
                }
            case "volunteer":
                if viewModel.locationSettings.enabled && !locationManager.isWithinBounds(center: CLLocationCoordinate2D(latitude: viewModel.locationSettings.center.latitude, longitude: viewModel.locationSettings.center.longitude), radius: viewModel.locationSettings.radius) {
                    GeoRestrictionView()
                } else {
                    TabView {
                        AnimalView()
                            .tabItem {
                                Label("Volunteer", systemImage: "pawprint.fill")
                            }
                        VisitorView()
                            .tabItem {
                                Label("Visitor", systemImage: "person.2.circle.fill")
                            }
                        VisitorSettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                    }
                    .onAppear {
                        print("Volunteer")
                        print(viewModel.shelterID)
                        print(viewModel.accountType)
                    }

                }
                
            default:
                TabView {
                    AnimalView()
                        .tabItem {
                            Label("Volunteer", systemImage: "pawprint.fill")
                        }
                    VisitorView()
                        .tabItem {
                            Label("Visitor", systemImage: "person.2.circle.fill")
                        }
                }
                .onAppear {
                    print("Other")
                    print(viewModel.shelterID)
                    print(viewModel.accountType)
                }
            }
        } else {
            LoginView()
                .onAppear {
                    viewModel.signOut()
                }
        }
    }
}
