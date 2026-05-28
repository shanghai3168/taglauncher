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
    let dragModeActive: Bool
    let draggingItemID: String?
    let onActivate: (String) -> Void
    let onHoverChange: (String, Bool) -> Void
    let canReorder: (String) -> Bool
    let onReorderBegan: (String) -> Void
    let onReorderMoved: (String, String) -> Void
    let onReorderEnded: () -> Void

    func makeNSView(context: Context) -> TagNavigationHostView {
        let view = TagNavigationHostView()
        view.update(
            items: items,
            orientation: orientation,
            contentInsets: contentInsets,
            dragModeActive: dragModeActive,
            draggingItemID: draggingItemID,
            onActivate: onActivate,
            onHoverChange: onHoverChange,
            canReorder: canReorder,
            onReorderBegan: onReorderBegan,
            onReorderMoved: onReorderMoved,
            onReorderEnded: onReorderEnded
        )
        return view
    }

    func updateNSView(_ nsView: TagNavigationHostView, context: Context) {
        nsView.update(
            items: items,
            orientation: orientation,
            contentInsets: contentInsets,
            dragModeActive: dragModeActive,
            draggingItemID: draggingItemID,
            onActivate: onActivate,
            onHoverChange: onHoverChange,
            canReorder: canReorder,
            onReorderBegan: onReorderBegan,
            onReorderMoved: onReorderMoved,
            onReorderEnded: onReorderEnded
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
        dragModeActive: Bool,
        draggingItemID: String?,
        onActivate: @escaping (String) -> Void,
        onHoverChange: @escaping (String, Bool) -> Void,
        canReorder: @escaping (String) -> Bool,
        onReorderBegan: @escaping (String) -> Void,
        onReorderMoved: @escaping (String, String) -> Void,
        onReorderEnded: @escaping () -> Void
    ) {
        documentView.update(
            items: items,
            orientation: orientation,
            contentInsets: contentInsets,
            dragModeActive: dragModeActive,
            draggingItemID: draggingItemID,
            onActivate: onActivate,
            onHoverChange: onHoverChange,
            canReorder: canReorder,
            onReorderBegan: onReorderBegan,
            onReorderMoved: onReorderMoved,
            onReorderEnded: onReorderEnded
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
    private var dragModeActive = false
    private var draggingItemID: String?
    private var onActivate: (String) -> Void = { _ in }
    private var onHoverChange: (String, Bool) -> Void = { _, _ in }
    private var canReorder: (String) -> Bool = { _ in false }
    private var onReorderBegan: (String) -> Void = { _ in }
    private var onReorderMoved: (String, String) -> Void = { _, _ in }
    private var onReorderEnded: () -> Void = {}

    override var isFlipped: Bool { true }

    func update(
        items: [TagNavigationItem],
        orientation: TagNavigationView.Orientation,
        contentInsets: NSEdgeInsets,
        dragModeActive: Bool,
        draggingItemID: String?,
        onActivate: @escaping (String) -> Void,
        onHoverChange: @escaping (String, Bool) -> Void,
        canReorder: @escaping (String) -> Bool,
        onReorderBegan: @escaping (String) -> Void,
        onReorderMoved: @escaping (String, String) -> Void,
        onReorderEnded: @escaping () -> Void
    ) {
        let oldNames = self.items.map(\.name)
        let newNames = items.map(\.name)
        let needsRebuild = Set(oldNames) != Set(newNames) || self.orientation != orientation
        self.items = items
        self.orientation = orientation
        self.contentInsets = contentInsets
        self.dragModeActive = dragModeActive
        self.draggingItemID = draggingItemID
        self.onActivate = onActivate
        self.onHoverChange = onHoverChange
        self.canReorder = canReorder
        self.onReorderBegan = onReorderBegan
        self.onReorderMoved = onReorderMoved
        self.onReorderEnded = onReorderEnded

        if needsRebuild {
            rebuildButtons()
        } else {
            reuseButtonsInCurrentOrder()
        }
        updateButtonRuntimeState()
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
            button.canReorder = { [weak self] tagID in self?.canReorder(tagID) ?? false }
            button.onReorderBegan = { [weak self] tagID in self?.onReorderBegan(tagID) }
            button.onReorderMoved = { [weak self] tagID, screenPoint in
                self?.handleReorderMove(tagID: tagID, screenPoint: screenPoint)
            }
            button.onReorderEnded = { [weak self] in self?.onReorderEnded() }
            addSubview(button)
            return button
        }
    }

    private func reuseButtonsInCurrentOrder() {
        let existing = Dictionary(uniqueKeysWithValues: buttons.map { ($0.itemName, $0) })
        buttons = items.compactMap { item in
            guard let button = existing[item.name] else { return nil }
            button.configure(item: item, orientation: orientation)
            return button
        }
    }

    private func updateButtonRuntimeState() {
        for button in buttons {
            button.configureRuntime(
                dragModeActive: dragModeActive && canReorder(button.itemName),
                isDragging: draggingItemID == button.itemName
            )
        }
    }

    private func handleReorderMove(tagID: String, screenPoint: NSPoint) {
        guard let window else { return }
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let point = convert(windowPoint, from: nil)
        guard let target = buttons.first(where: { button in
            button.itemName != tagID
                && canReorder(button.itemName)
                && button.frame.insetBy(dx: -4, dy: -4).contains(point)
        }) else { return }
        onReorderMoved(tagID, target.itemName)
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
    var canReorder: (String) -> Bool = { _ in false }
    var onReorderBegan: (String) -> Void = { _ in }
    var onReorderMoved: (String, NSPoint) -> Void = { _, _ in }
    var onReorderEnded: () -> Void = {}

    private var item: TagNavigationItem
    private var orientation: TagNavigationView.Orientation
    private var trackingAreaRef: NSTrackingArea?
    private var isMouseInside = false
    private var dragModeActive = false
    private var isDragging = false

    var itemName: String { item.name }

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

    func configureRuntime(dragModeActive: Bool, isDragging: Bool) {
        self.dragModeActive = dragModeActive
        self.isDragging = isDragging
        updateAppearance()
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

    override func mouseDown(with event: NSEvent) {
        guard canReorder(item.id) else {
            onActivate(item.id)
            return
        }

        let start = Date()
        let longPressDuration: TimeInterval = 0.35
        var reorderActive = false
        var finished = false

        while !finished {
            if !reorderActive && Date().timeIntervalSince(start) >= longPressDuration {
                reorderActive = true
                onReorderBegan(item.id)
            }

            let nextEvent = window?.nextEvent(
                matching: [.leftMouseDragged, .leftMouseUp],
                until: Date().addingTimeInterval(0.04),
                inMode: .eventTracking,
                dequeue: true
            )

            guard let nextEvent else { continue }
            switch nextEvent.type {
            case .leftMouseDragged:
                if reorderActive {
                    onReorderMoved(item.id, NSEvent.mouseLocation)
                }
            case .leftMouseUp:
                if reorderActive {
                    onReorderEnded()
                } else {
                    onActivate(item.id)
                }
                finished = true
            default:
                break
            }
        }
    }

    @objc private func performActivation() {
        onActivate(item.id)
    }

    private func updateAppearance() {
        let background = TagColor.nsColor(for: item.colorIndex)
        layer?.backgroundColor = background.cgColor
        layer?.cornerRadius = orientation == .horizontal ? 7 : 6
        layer?.shadowColor = NSColor.black.withAlphaComponent(isDragging ? 0.38 : 0.20).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = isDragging ? 14 : 3
        layer?.shadowOffset = NSSize(width: 0, height: isDragging ? -7 : -1)
        layer?.zPosition = isDragging ? 20 : 0
        alphaValue = dragModeActive ? (isDragging ? 1.0 : 0.62) : 1.0

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
