import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferencesVM = PreferencesViewModel()

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Auto-navigate to new images", isOn: $preferencesVM.autoNavigateToNewImages)
                    .help("When enabled, automatically switches to newly captured images")
            }

            Section("Appearance") {
                Picker("Thumbnail Size", selection: $preferencesVM.thumbnailSize) {
                    ForEach(PreferencesViewModel.ThumbnailSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("HUD Display") {
                Toggle("Show star rating", isOn: $preferencesVM.showRatingInHUD)
                Toggle("Show color tag", isOn: $preferencesVM.showColorTagInHUD)
                Toggle("Show EXIF info", isOn: $preferencesVM.showExifInHUD)
            }

            Section("Connection") {
                LabeledContent("Last Server") {
                    if preferencesVM.lastServerHost.isEmpty {
                        Text("None")
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(preferencesVM.lastServerHost):\(preferencesVM.lastServerPort)")
                            .foregroundColor(.secondary)
                    }
                }

                Button("Clear Connection History") {
                    preferencesVM.lastServerHost = ""
                    preferencesVM.lastServerPort = 8080
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
    }
}

#Preview {
    PreferencesView()
}
