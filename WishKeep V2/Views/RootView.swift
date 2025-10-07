import SwiftUI
import SwiftData
import UIKit

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @State private var showBanner: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var blurPrivacy: Bool = false

    var body: some View {
        ZStack {
            WKThemeBackground()
            
            NavigationStack {
                NoteListView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                NavigationLink(destination: JarsView()) { Label("Jars", systemImage: "tray.full") }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                LiquidGlassButton()
                            }
                        }
            }
        }
        .wkTheme(colorScheme == .dark ? .dark : .light)
        .overlay(alignment: .top) {
            if showBanner { ToastView(text: "Saved to Inbox").padding(.top, 12).transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .overlay {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(blurPrivacy ? 1 : 0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showInboxBanner)) { _ in
            Haptic.success()
            withAnimation(.spring()) { showBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut) { showBanner = false }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoLibraryChangedReimport)) { _ in
            ImportService.shared.scanForNewScreenshots(context: context)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: blurPrivacy = false
            case .inactive, .background: blurPrivacy = true
            @unknown default: break
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.preview.container)
}




