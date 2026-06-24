import SwiftUI
import AppKit

struct EditAppsHeaderView: View {
    let theme: AppGridTheme
    let operation: EditTagOperation
    let hintText: String
    let confirmTitle: String
    let isConfirmDisabled: Bool
    let notchHeight: CGFloat
    let onExit: () -> Void
    let onSelectOperation: (EditTagOperation) -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onExit) {
                Label(tr("edit.exit"), systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.editPrimaryTextColor)
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(theme.editControlSurfaceColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(theme.editControlStrokeColor, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(tr("edit.exit"))
            .shadow(color: theme.editButtonShadowColor, radius: 10, y: 4)

            Spacer(minLength: 20)

            VStack(alignment: .trailing, spacing: 5) {
                HStack(alignment: .center, spacing: 14) {
                    EditOperationPicker(
                        theme: theme,
                        operation: operation,
                        onSelect: onSelectOperation
                    )

                    EditConfirmButton(
                        theme: theme,
                        title: confirmTitle,
                        isDisabled: isConfirmDisabled,
                        action: onConfirm
                    )
                }

                Text(hintText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.editSecondaryTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 460, alignment: .trailing)
                    .help(hintText)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 24)
        .padding(.top, notchHeight > 0 ? notchHeight + 10 : 20)
        .padding(.bottom, 10)
        .background(theme.editToolbarSurfaceColor)
    }
}

private struct EditOperationPicker: View {
    let theme: AppGridTheme
    let operation: EditTagOperation
    let onSelect: (EditTagOperation) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(tr("edit.operationLabel"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.editSecondaryTextColor)

            HStack(spacing: 14) {
                EditOperationModeButton(
                    theme: theme,
                    operation: operation,
                    mode: .add,
                    titleKey: "edit.modeAdd",
                    onSelect: onSelect
                )
                EditOperationModeButton(
                    theme: theme,
                    operation: operation,
                    mode: .remove,
                    titleKey: "edit.modeRemove",
                    onSelect: onSelect
                )
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.editControlSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.editControlStrokeColor, lineWidth: 1)
        )
        .shadow(color: theme.editButtonShadowColor, radius: 10, y: 4)
    }
}

private struct EditOperationModeButton: View {
    let theme: AppGridTheme
    let operation: EditTagOperation
    let mode: EditTagOperation
    let titleKey: String
    let onSelect: (EditTagOperation) -> Void

    private var isActive: Bool {
        operation == mode
    }

    var body: some View {
        Button {
            onSelect(mode)
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isActive ? theme.editAccentColor : theme.editInactiveIndicatorColor,
                            lineWidth: 1.6
                        )
                        .frame(width: 13, height: 13)
                    if isActive {
                        Circle()
                            .fill(theme.editAccentColor)
                            .frame(width: 7, height: 7)
                    }
                }

                Text(tr(titleKey))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? theme.editPrimaryTextColor : theme.editSecondaryTextColor)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .help(tr(titleKey))
    }
}

private struct EditConfirmButton: View {
    let theme: AppGridTheme
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isDisabled ? theme.editDisabledTextColor : theme.editConfirmForegroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(minWidth: 116)
                .frame(height: 34)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isDisabled ? theme.editDisabledSurfaceColor : theme.editAccentColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isDisabled ? theme.editControlStrokeColor : theme.editAccentColor.opacity(0.72), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: isDisabled ? Color.clear : theme.editButtonShadowColor, radius: 12, y: 5)
    }
}

struct EditAppsSidebarIntroView: View {
    let theme: AppGridTheme
    let width: CGFloat
    let horizontalInset: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tr("edit.selectTags"))
                .font(.caption)
                .foregroundStyle(theme.editSecondaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(tr("edit.dragHint"))
                .font(.caption2)
                .foregroundStyle(theme.editTertiaryTextColor)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, horizontalInset)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(width: width, alignment: .leading)
    }
}

struct EditSelectableTagItem: View {
    let tagName: String
    let displayName: String
    let colorIndex: Int
    let operation: EditTagOperation
    let isSelected: Bool
    let isRemovableCandidate: Bool
    let theme: AppGridTheme
    let onToggle: () -> Void

    private var isEnabled: Bool {
        operation == .add || isRemovableCandidate
    }

    private var showsPendingRemoval: Bool {
        operation == .remove && isRemovableCandidate && !isSelected
    }

    private var isUncommon: Bool {
        tagName == TagDatabase.uncommonTagKey
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isSelected ? theme.editAccentColor : theme.editInactiveIndicatorColor.opacity(isEnabled ? 1.0 : 0.56))
                .frame(width: 16, height: 16)
                .overlay(
                    isSelected
                    ? Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                    : nil
                )

            Text(displayName)
                .font(.system(size: 13, weight: isUncommon ? .semibold : .medium))
                .foregroundStyle(isEnabled ? theme.editPrimaryTextColor : theme.editDisabledTextColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if isUncommon {
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isEnabled ? theme.editSecondaryTextColor : theme.editDisabledTextColor)
                        .frame(width: 16, height: 16)
                }
                if showsPendingRemoval {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.red.opacity(theme.usesDarkGlass ? 0.96 : 0.84))
                        .frame(width: 16, height: 16)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                } else if operation == .remove {
                    Color.clear.frame(width: 16, height: 16)
                }
            }
            .frame(
                minWidth: operation == .remove
                    ? (isUncommon ? 36 : 16)
                    : (isUncommon ? 16 : 0),
                alignment: .trailing
            )
            .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 27)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    Color(
                        nsColor: TagColor.nsColor(for: colorIndex)
                            .withAlphaComponent(isEnabled ? (isUncommon ? 0.26 : 0.34) : 0.16)
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.editControlStrokeColor.opacity(isSelected ? 1.0 : 0.44), lineWidth: isSelected ? 1.1 : 0.6)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            guard isEnabled else { return }
            onToggle()
        }
        .opacity(isEnabled ? 1.0 : 0.58)
        .animation(.easeInOut(duration: 0.15), value: showsPendingRemoval)
    }
}

struct EditableAppSelectionItem: View {
    let app: AppInfo
    let iconSize: CGFloat
    let isSelected: Bool
    let theme: AppGridTheme
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)

                    Circle()
                        .fill(isSelected ? theme.editAccentColor : theme.editInactiveIndicatorColor)
                        .frame(width: 20, height: 20)
                        .overlay(
                            isSelected
                            ? Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                            : nil
                        )
                        .offset(x: 6, y: -6)
                }

                Text(app.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.editPrimaryTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: iconSize + 20)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isSelected ? 1.0 : 0.65)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? theme.editControlSurfaceColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? theme.editControlStrokeColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EditActionFeedbackBubble: View {
    let title: String
    let message: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            ScrollView(.vertical, showsIndicators: true) {
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.84))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: .black.opacity(0.34), radius: 24, y: 16)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        )
    }
}

struct UncategorizedDropConfirmBubble: View {
    let title: String
    let message: String
    let doNotRemindTitle: String
    @Binding var doNotRemind: Bool
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.84))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                doNotRemind.toggle()
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(doNotRemind ? Color.accentColor : Color.white.opacity(0.10))
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.92), lineWidth: 1.6)
                        if doNotRemind {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 18, height: 18)

                    Text(doNotRemindTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Spacer(minLength: 0)

                Button(action: onCancel) {
                    Text(cancelTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(width: 92, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.13))
                        )
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: .black.opacity(0.34), radius: 24, y: 16)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        )
        .onExitCommand(perform: onCancel)
    }
}

struct TagRemovalDropConfirmBubble: View {
    let title: String
    let message: String
    let doNotRemindTitle: String
    @Binding var doNotRemind: Bool
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: { DispatchQueue.main.async(execute: onCancel) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.84))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                doNotRemind.toggle()
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(doNotRemind ? Color.accentColor : Color.white.opacity(0.10))
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.92), lineWidth: 1.6)
                        if doNotRemind {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 18, height: 18)

                    Text(doNotRemindTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Spacer(minLength: 0)

                Button(action: { DispatchQueue.main.async(execute: onCancel) }) {
                    Text(cancelTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(width: 92, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.13))
                        )
                }
                .buttonStyle(.plain)

                Button(action: { DispatchQueue.main.async(execute: onConfirm) }) {
                    Text(confirmTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: .black.opacity(0.34), radius: 24, y: 16)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        )
        .onExitCommand(perform: onCancel)
    }
}
