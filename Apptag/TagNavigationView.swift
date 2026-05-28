import AppKit
import SwiftUI

struct TagNavigationItem: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let colorIndex: Int
}

struct TagNavigationView: NSViewRepresentable {
    enum Orientation: Equatable {
        case horizontal
        case vertical
    }

    let items: [TagNavigationItem]
    let orientation: Orientation
    let contentInsets: NSEdgeInsets
    let onActivate: (String) -> Void
    let onHoverChange: (String, Bool) -> Void

    func makeNSView(context: Context) -> TagNavigationHostView {
        let view = TagNavigationHostView()
        view.update(
            items: items,
            orientation: orientation,
            contentInsets: contentInsets,
            onActivate: onActivate,
            onHoverChange: onHoverChange
        )
        return view
    }

    func updateNSView(_ nsView: TagNavigationHostView, context: Context) {
        nsView.update(
            items: items,
            orientation: orientation,
            contentInsets: contentInsets,
            onActivate: onActivate,
            onHoverChange: onHoverChange
        )
    }
}

final class TagNavigationHostView: NSView {
    private let scrollView = NSScrollView()
    private let documentView = TagNavigationDocumentView()

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update(
        items: [TagNavigationItem],
        orientation: TagNavigationView.Orientation,
        contentInsets: NSEdgeInsets,
        onActivate: @escaping (String) -> Void,
        onHoverChange: @escaping (String, Bool) -> Void
    ) {
        documentView.update(
            items: items,
            orientation: orientation,
            contentInsets: contentInsets,
            onActivate: onActivate,
            onHoverChange: onHoverChange
        )
        scrollView.hasHorizontalScroller = orientation == .horizontal
        scrollView.hasVerticalScroller = orientation == .vertical
        needsLayout = true
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds
        let visibleSize = scrollView.contentView.bounds.size
        documentView.frame = NSRect(
            origin: .zero,
            size: documentView.contentSize(fitting: visibleSize)
        )
        documentView.needsLayout = true
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.documentView = documentView
        addSubview(scrollView)
    }
}

final class TagNavigationDocumentView: NSView {
    private var items: [TagNavigationItem] = []
    private var orientation: TagNavigationView.Orientation = .horizontal
    private var contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    private var buttons: [TagNavigationButton] = []
    private var onActivate: (String) -> Void = { _ in }
    private var onHoverChange: (String, Bool) -> Void = { _, _ in }

    override var isFlipped: Bool { true }

    func update(
        items: [TagNavigationItem],
        orientation: TagNavigationView.Orientation,
        contentInsets: NSEdgeInsets,
        onActivate: @escaping (String) -> Void,
        onHoverChange: @escaping (String, Bool) -> Void
    ) {
        let needsRebuild = self.items != items || self.orientation != orientation
        self.items = items
        self.orientation = orientation
        self.contentInsets = contentInsets
        self.onActivate = onActivate
        self.onHoverChange = onHoverChange

        if needsRebuild {
            rebuildButtons()
        } else {
            for (button, item) in zip(buttons, items) {
                button.configure(item: item, orientation: orientation)
            }
        }
        needsLayout = true
    }

    func contentSize(fitting visibleSize: NSSize) -> NSSize {
        switch orientation {
        case .horizontal:
            let width = buttons.reduce(contentInsets.left + contentInsets.right) { total, button in
                total + button.preferredSize.width
            } + CGFloat(max(0, buttons.count - 1)) * 8
            let height = max(visibleSize.height, contentInsets.top + 28 + contentInsets.bottom)
            return NSSize(width: max(width, visibleSize.width), height: height)
        case .vertical:
            let rowHeight: CGFloat = 28
            let height = contentInsets.top
                + CGFloat(buttons.count) * rowHeight
                + CGFloat(max(0, buttons.count - 1)) * 6
                + contentInsets.bottom
            return NSSize(width: max(visibleSize.width, 1), height: max(height, visibleSize.height))
        }
    }

    override func layout() {
        super.layout()
        switch orientation {
        case .horizontal:
            layoutHorizontal()
        case .vertical:
            layoutVertical()
        }
    }

    private func rebuildButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.map { item in
            let button = TagNavigationButton(item: item, orientation: orientation)
            button.onActivate = { [weak self] tagID in self?.onActivate(tagID) }
            button.onHoverChange = { [weak self] tagID, active in self?.onHoverChange(tagID, active) }
            addSubview(button)
            return button
        }
    }

    private func layoutHorizontal() {
        var x = contentInsets.left
        let height: CGFloat = 28
        let y = max(contentInsets.top, (bounds.height - height) / 2)
        for button in buttons {
            let size = button.preferredSize
            button.frame = NSRect(x: x, y: y, width: size.width, height: height)
            x += size.width + 8
        }
    }

    private func layoutVertical() {
        let rowHeight: CGFloat = 28
        let width = max(1, bounds.width - contentInsets.left - contentInsets.right)
        var y = contentInsets.top
        for button in buttons {
            button.frame = NSRect(x: contentInsets.left, y: y, width: width, height: rowHeight)
            y += rowHeight + 6
        }
    }
}

final class TagNavigationButton: NSButton {
    var onActivate: (String) -> Void = { _ in }
    var onHoverChange: (String, Bool) -> Void = { _, _ in }

    private var item: TagNavigationItem
    private var orientation: TagNavigationView.Orientation
    private var trackingAreaRef: NSTrackingArea?
    private var isMouseInside = false

    var preferredSize: NSSize {
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let textWidth = (item.name as NSString).size(withAttributes: [.font: font]).width
        switch orientation {
        case .horizontal:
            return NSSize(width: ceil(textWidth + 24), height: 28)
        case .vertical:
            return NSSize(width: ceil(textWidth + 20), height: 28)
        }
    }

    init(item: TagNavigationItem, orientation: TagNavigationView.Orientation) {
        self.item = item
        self.orientation = orientation
        super.init(frame: .zero)
        isBordered = false
        setButtonType(.momentaryChange)
        target = self
        action = #selector(performActivation)
        wantsLayer = true
        configure(item: item, orientation: orientation)
    }

    required init?(coder: NSCoder) {
        self.item = TagNavigationItem(name: "", colorIndex: 0)
        self.orientation = .horizontal
        super.init(coder: coder)
    }

    func configure(item: TagNavigationItem, orientation: TagNavigationView.Orientation) {
        self.item = item
        self.orientation = orientation
        title = item.name
        alignment = orientation == .horizontal ? .center : .left
        setAccessibilityLabel(item.name)
        updateAppearance()
        needsLayout = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        trackingAreaRef = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard !isMouseInside else { return }
        isMouseInside = true
        onHoverChange(item.id, true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard isMouseInside else { return }
        isMouseInside = false
        onHoverChange(item.id, false)
    }

    @objc private func performActivation() {
        onActivate(item.id)
    }

    private func updateAppearance() {
        let background = TagColor.nsColor(for: item.colorIndex)
        layer?.backgroundColor = background.cgColor
        layer?.cornerRadius = orientation == .horizontal ? 7 : 6
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.20).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 3
        layer?.shadowOffset = NSSize(width: 0, height: -1)

        let textColor: NSColor = (item.colorIndex == 0 || item.colorIndex == 5) ? .labelColor : .white
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        if orientation == .vertical {
            paragraph.firstLineHeadIndent = 10
            paragraph.headIndent = 10
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        attributedTitle = NSAttributedString(string: item.name, attributes: attributes)
    }
}
