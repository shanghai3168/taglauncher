import SwiftUI

enum SmartStartNoticeMode {
    case autoApplied
    case suggestionOnly
    case manuallyApplied
}

struct SmartStartNotice: Identifiable {
    let id = UUID()
    let mode: SmartStartNoticeMode
    let title: String
    let message: String
    let summary: SmartStartSummary
}

struct SmartStartNoticeOverlay: View {
    let notice: SmartStartNotice?
    let onDismiss: () -> Void
    let onApply: () -> Void
    let onUndo: () -> Void

    var body: some View {
        GeometryReader { proxy in
            if let notice {
                let panelWidth = min(560, max(320, proxy.size.width - 64))

                ZStack {
                    Color.black.opacity(0.10)
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        Image(systemName: notice.mode == .suggestionOnly ? "sparkles" : "checkmark.seal.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 58, height: 58)
                            .background(
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                            )

                        VStack(spacing: 8) {
                            Text(notice.title)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)

                            Text(notice.message)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 12) {
                            switch notice.mode {
                            case .suggestionOnly:
                                Button(tr("smartstart.later"), action: onDismiss)
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)

                                Button(tr("smartstart.apply"), action: onApply)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                            case .autoApplied, .manuallyApplied:
                                if notice.summary.backupPath != nil {
                                    Button(tr("smartstart.undo"), action: onUndo)
                                        .buttonStyle(.bordered)
                                        .controlSize(.large)
                                }
                                Button(tr("smartstart.ok"), action: onDismiss)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 26)
                    .frame(width: panelWidth)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.26), radius: 28, y: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(650)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(notice != nil)
    }
}
