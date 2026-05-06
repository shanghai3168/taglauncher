import SwiftUI

// MARK: - Reusable Tag Editor (overlay edit mode + Preferences)

/// A scrollable tag list with inline rename, color swatches, delete, and add-new-tag.
/// All changes (rename, delete, setColor) are saved to the local tag database.
struct TagEditorView: View {
    @Binding var tagColors: [String: Int]
    let excludedTagNames: Set<String>
    var onRefresh: (() -> Void)?

    @State private var editingTagName: String? = nil
    @State private var editingTagText: String = ""
    @State private var addingNewTag = false
    @State private var newTagNameText = ""
    @State private var newTagColorIndex = 0

    private var sortedTagNames: [String] {
        tagColors.keys
            .filter { !excludedTagNames.contains($0) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            // "New Tag" button at top
            HStack {
                Spacer()
                Button {
                    addingNewTag = true
                    newTagNameText = ""
                    newTagColorIndex = 0
                } label: {
                    Label("New Tag", systemImage: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 0) {
                    if sortedTagNames.isEmpty && !addingNewTag {
                        Text("No tags yet. Click \"New Tag\" to create one.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 40)
                    }
                    ForEach(sortedTagNames, id: \.self) { tagName in
                        tagEditRow(tagName)
                        Divider().opacity(0.15).padding(.leading, 16)
                    }
                    if addingNewTag {
                        newTagRow()
                        Divider().opacity(0.15).padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Tag Row

    private func tagEditRow(_ tagName: String) -> some View {
        let colorIndex = tagColors[tagName] ?? 0
        return HStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(TagColor.allIndices, id: \.self) { idx in
                    ColorSwatch(index: idx, isSelected: idx == colorIndex) {
                        TagEditor.setColor(idx, for: tagName)
                        tagColors[tagName] = idx
                        onRefresh?()
                    }
                }
            }

            if editingTagName == tagName {
                MacTextField(
                    text: $editingTagText,
                    placeholder: "Tag name",
                    onSubmit: { commitTagRename(tagName) }
                )
                .frame(width: 160, height: 24)
                Button("Save") { commitTagRename(tagName) }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                Button("Cancel") { editingTagName = nil }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            } else {
                Text(tagName).font(.system(size: 14)).frame(width: 160, alignment: .leading)
                Button { startRename(tagName) } label: {
                    Image(systemName: "pencil").font(.system(size: 11))
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Button(role: .destructive) { deleteTag(tagName) } label: {
                    Image(systemName: "trash").font(.system(size: 11))
                }
                .buttonStyle(.plain).foregroundStyle(.red)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
    }

    // MARK: - New Tag Row

    private func newTagRow() -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(TagColor.allIndices, id: \.self) { idx in
                    ColorSwatch(index: idx, isSelected: idx == newTagColorIndex) {
                        newTagColorIndex = idx
                    }
                }
            }
            MacTextField(
                text: $newTagNameText,
                placeholder: "New tag name",
                onSubmit: { addNewTag() }
            )
            .frame(width: 160, height: 24)
            Button("Add") { addNewTag() }
                .buttonStyle(.borderedProminent).controlSize(.small)
            Button("Cancel") { addingNewTag = false; newTagNameText = "" }
                .buttonStyle(.plain).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
    }

    // MARK: - Actions

    private func startRename(_ name: String) {
        editingTagName = name
        editingTagText = name
    }

    private func commitTagRename(_ oldName: String) {
        let newName = editingTagText.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty, newName != oldName else { editingTagName = nil; return }
        TagEditor.renameTag(from: oldName, to: newName)
        tagColors[newName] = tagColors[oldName]
        tagColors.removeValue(forKey: oldName)
        editingTagName = nil
        // Don't call onRefresh — re-scan may re-discover old tag from
        // SIP-protected apps where xattr write silently fails.
    }

    /// Add a new tag name+color to the local registry only (no xattr write until
    /// the tag is assigned to apps via "Edit App Categories").
    /// Does NOT call onRefresh — would overwrite tagColors with scan results.
    private func addNewTag() {
        let name = newTagNameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        tagColors[name] = newTagColorIndex
        addingNewTag = false
        newTagNameText = ""
    }

    private func deleteTag(_ name: String) {
        TagEditor.deleteTagCompletely(name)
        tagColors.removeValue(forKey: name)
        onRefresh?()
    }
}
