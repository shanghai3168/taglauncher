import SwiftUI
import AppKit

// MARK: - App Grid Shared Types

enum AppGridItemMetrics {
    static let hoverScale: CGFloat = 1.22
    static let labelHeight: CGFloat = 14

    static func stableWidth(iconSize: CGFloat) -> CGFloat {
        iconSize * hoverScale + 8
    }

    static func stableHeight(iconSize: CGFloat) -> CGFloat {
        iconSize * hoverScale + labelHeight + 22
    }
}

enum AppBubbleHoverEvent {
    case entered(canShowBubble: Bool)
    case exited
}

enum BubblePlacement {
    case above
    case below
}

struct AppNameBubble: View {
    let appName: String
    let note: String?
    let isEditing: Bool
    let placement: BubblePlacement
    let arrowOffset: CGFloat
    @Binding var draftNote: String
    var noteFocused: FocusState<Bool>.Binding
    let onCommit: () -> Void
    let onCancel: () -> Void

    private var displayNote: String {
        note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        content
        .onExitCommand(perform: onCancel)
    }

    private var content: some View {
        VStack(spacing: isEditing || !displayNote.isEmpty ? 8 : 0) {
            Text(appName)
                .font(.system(size: isEditing ? 22 : 24, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity)

            if isEditing {
                VStack(alignment: .trailing, spacing: 4) {
                    TextField(tr("appNote.placeholder"), text: limitedDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.white.opacity(0.12))
                        )
                        .focused(noteFocused)
                        .onSubmit(onCommit)
                    Text("\(draftNote.count) / \(TagDatabase.maxAppNoteLength)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
            } else if !displayNote.isEmpty {
                Text(displayNote)
                    .font(.system(size: 14, weight: .medium))
                    .lineSpacing(2)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, isEditing ? 22 : 24)
        .padding(.vertical, isEditing ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: .black.opacity(0.34), radius: 24, y: 16)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        )
        .overlay(alignment: placement == .above ? .bottom : .top) {
            BubbleArrow(placement: placement)
                .fill(Color.black.opacity(0.92))
                .frame(width: 18, height: 9)
                .offset(x: arrowOffset, y: placement == .above ? 8 : -8)
        }
    }

    private var limitedDraft: Binding<String> {
        Binding(
            get: { draftNote },
            set: { draftNote = String($0.prefix(TagDatabase.maxAppNoteLength)) }
        )
    }
}

private struct BubbleArrow: Shape {
    let placement: BubblePlacement

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch placement {
        case .above:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        case .below:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}
