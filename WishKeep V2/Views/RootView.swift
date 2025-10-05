import SwiftUI
internal import CoreData
import UIKit

struct RootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showBanner: Bool = false
    #if DEBUG
    @State private var showOCRDebug: Bool = false
    #endif
    @Environment(\.scenePhase) private var scenePhase
    @State private var blurPrivacy: Bool = false

    var body: some View {
        NavigationStack {
            NoteListView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink(destination: JarsView()) { Label("Jars", systemImage: "tray.full") }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            if UIPasteboard.general.hasStrings { ClipboardManager.shared.saveClipboardIfAvailable(context: viewContext) }
                        } label: { Image(systemName: "doc.on.clipboard") }
                        Button {
                            ImportService.shared.scanForNewScreenshots(context: viewContext)
                        } label: {
                            Image(systemName: "photo.on.rectangle")
                        }
                    }
                }
        }
        .overlay(alignment: .top) {
            if showBanner {
                Text("Saved to Inbox")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .shadow(radius: 4)
            }
            #if DEBUG
            if showOCRDebug {
                OCRDebugOverlay()
                    .transition(.opacity)
            }
            #endif
        }
        .overlay {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(blurPrivacy ? 1 : 0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showInboxBanner)) { _ in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring()) { showBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut) { showBanner = false }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoLibraryChangedReimport)) { _ in
            ImportService.shared.scanForNewScreenshots(context: viewContext)
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(showOCRDebug ? "Hide Boxes" : "Show Boxes") { withAnimation { showOCRDebug.toggle() } }
            }
        }
        #endif
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
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#if DEBUG
private struct OCRDebugOverlay: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(OCRDebugStore.lastLines) { line in
                    let rect = line.rect
                    let frame = CGRect(
                        x: rect.minX * geo.size.width,
                        y: (1 - rect.maxY) * geo.size.height,
                        width: rect.width * geo.size.width,
                        height: rect.height * geo.size.height
                    )
                    Rectangle()
                        .stroke(line.side == .left ? .green : .blue, lineWidth: 1)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.minX + frame.width/2, y: frame.minY + frame.height/2)
                        .overlay(
                            Text(String(format: "%.2f", line.confidence))
                                .font(.caption2)
                                .padding(2)
                                .background(.thinMaterial)
                                .cornerRadius(4)
                                .position(x: frame.minX + 18, y: frame.minY + 8)
                        )
                }
            }
            .ignoresSafeArea()
        }
    }
}
#endif



