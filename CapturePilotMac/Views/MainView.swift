import SwiftUI

struct MainView: View {
    @StateObject private var appVM = AppViewModel()

    var body: some View {
        Group {
            switch appVM.connectionVM.connectionState {
            case .disconnected, .discovering:
                ServerDiscoveryView()
                    .environmentObject(appVM.connectionVM)
                    .environmentObject(appVM.preferencesVM)

            case .connecting:
                ConnectionProgressView()

            case .connected:
                GalleryView()
                    .environmentObject(appVM)
                    .environmentObject(appVM.galleryVM)
                    .environmentObject(appVM.viewerVM)
                    .environmentObject(appVM.preferencesVM)

            case .error(let error):
                ConnectionErrorView(error: error)
                    .environmentObject(appVM.connectionVM)
            }
        }
        .id(appVM.connectionVM.connectionState)
        .preferredColorScheme(.dark)
        .onAppear {
            appVM.connectionVM.startDiscovery()
        }
    }
}

struct ConnectionProgressView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Connecting...")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ConnectionErrorView: View {
    let error: ConnectionError
    @EnvironmentObject var connectionVM: ConnectionViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Connection Error")
                .font(.title)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if error == .authenticationFailed {
                VStack(spacing: 12) {
                    SecureField("Password", text: $connectionVM.password)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)

                    Button("Retry with Password") {
                        connectionVM.retryLastConnection()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                HStack(spacing: 16) {
                    Button("Try Again") {
                        connectionVM.retryLastConnection()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Browse Servers") {
                        connectionVM.startDiscovery()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    MainView()
}
