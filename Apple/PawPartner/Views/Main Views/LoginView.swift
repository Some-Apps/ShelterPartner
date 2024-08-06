import SwiftUI
import AlertToast

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                    }
                    Spacer() // Top spacer
                    Image("Dog")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? geometry.size.width * 0.3 : geometry.size.width * 0.9)
                        .onAppear {
                            viewModel.lastSync = viewModel.dateFormatter.string(from: Date())
                        }
                        .padding(.bottom)
                    VStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            TextField("Email", text: $viewModel.email)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                        }
                        VStack(alignment: .leading) {
                            SecureField("Password", text: $viewModel.password)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        Button("Login", action: {
                            viewModel.login()
                        })
                        .font(.largeTitle)
                        .buttonStyle(.bordered)
                        .fontWeight(.bold)
                        .tint(.customBlue)
                        
                        Text("Please do not share your login with anybody. You can request an additional admin account by emailing me or create volunteer accounts from within the app.")
                            .multilineTextAlignment(.center)
                        HStack {
                            if let url = URL(string: viewModel.newShelterForm) {
                                Button(action: {
                                    viewModel.showNewShelterForm = true
                                }) {
                                    Text("Create New Shelter")
                                }
                                .sheet(isPresented: $viewModel.showNewShelterForm) {
                                    SafariView(url: url)
                                }
                            }
                            if let url = URL(string: viewModel.tutorialsURL) {
                                Button(action: {
                                    viewModel.showTutorials = true
                                }) {
                                    Text("Tutorials/Documentation")
                                }
                                .sheet(isPresented: $viewModel.showTutorials) {
                                    SafariView(url: url)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                    .frame(maxWidth: 500)
                    Spacer() // Bottom spacer
                    Spacer()
                }
                .frame(minHeight: geometry.size.height * 1.25)
                .padding(.horizontal, 20)
            }
            .background(Color(.systemBackground))
        }
        .edgesIgnoringSafeArea(.bottom)
        .toast(isPresenting: $viewModel.showLoginError, duration: 3) {
            AlertToast(type: .error(.red), title: "Your username or password is incorrect.")
        }
        .toast(isPresenting: $viewModel.isLoginInProgress) {
            AlertToast(type: .loading)
        }
        .onAppear {
            viewModel.fetchSignUpForm()
        }
        .onDisappear {
            viewModel.loginListener?.remove()
        }
    }
}
