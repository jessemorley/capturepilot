import SwiftUI

struct ServerDiscoveryView: View {
    @EnvironmentObject var connectionVM: ConnectionViewModel
    @EnvironmentObject var preferencesVM: PreferencesViewModel

    @State private var showManualEntry = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main content (centered)
                VStack(spacing: 32) {
                    // Logo Section
                    VStack(spacing: 16) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundColor(.white.opacity(0.9))

                        Text("Capture Pilot")
                            .font(.system(size: 30, weight: .bold))
                            .tracking(-0.5)
                            .foregroundColor(.white)

                        Text("Connect to Capture One")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }

                    // Server List or Loading
                    if connectionVM.discoveredServers.isEmpty {
                        // Loading/Searching Section
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color(white: 0.4))

                            Text("Searching for Capture One...")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(white: 0.8))

                            Text("Make sure Capture One is running with Capture Pilot enabled in Preferences")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 280)
                                .lineSpacing(4)
                        }
                        .padding(.top, 48)
                    } else {
                        // Server List
                        VStack(spacing: 8) {
                            ForEach(connectionVM.discoveredServers) { server in
                                ServerRowView(server: server) {
                                    connectionVM.connect(to: server)
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 24)
                    }
                }
                .offset(y: -40) // Shift content slightly up

                Spacer()

                // Footer with manual entry button
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)

                    if showManualEntry {
                        ManualConnectionView()
                            .environmentObject(connectionVM)
                            .padding(.vertical, 16)
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showManualEntry = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "keyboard")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                Text("Enter address manually")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(white: 0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.buttonBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.borderSubtle, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 20)
                    }
                }
                .frame(height: 80)
                .background(Color.black)
            }
        }
    }
}

struct ServerRowView: View {
    let server: DiscoveredServer
    let onConnect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onConnect) {
            HStack(spacing: 16) {
                Image(systemName: "display")
                    .font(.system(size: 20))
                    .foregroundColor(Color(white: 0.6))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(server.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Text(server.address)
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.buttonHover : Color.buttonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? Color.borderLight : Color.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct ManualConnectionView: View {
    @EnvironmentObject var connectionVM: ConnectionViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Host", text: $connectionVM.manualHost)
                    .textFieldStyle(DarkTextFieldStyle())
                    .frame(width: 180)

                Text(":")
                    .foregroundColor(Color(white: 0.5))

                TextField("Port", text: $connectionVM.manualPort)
                    .textFieldStyle(DarkTextFieldStyle())
                    .frame(width: 60)
            }

            if connectionVM.showPasswordField {
                SecureField("Password (optional)", text: $connectionVM.password)
                    .textFieldStyle(DarkTextFieldStyle())
                    .frame(width: 256)
            }

            HStack(spacing: 8) {
                if connectionVM.isConnecting {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Color(white: 0.5))
                    Text("Connecting...")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                } else {
                    Button {
                        connectionVM.connectManually()
                    } label: {
                        Text("Connect")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(connectionVM.manualHost.isEmpty)
                    .opacity(connectionVM.manualHost.isEmpty ? 0.5 : 1.0)
                }
            }

            // Connection status feedback
            if case .error(let error) = connectionVM.connectionState {
                Text(error.localizedDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Dark Text Field Style
struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.borderSubtle, lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 13))
    }
}

#Preview {
    ServerDiscoveryView()
        .environmentObject(ConnectionViewModel(
            client: CapturePilotClient(),
            preferencesVM: PreferencesViewModel()
        ))
        .environmentObject(PreferencesViewModel())
        .frame(width: 400, height: 500)
}
