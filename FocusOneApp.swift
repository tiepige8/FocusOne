import SwiftUI

@main
struct FocusOneApp: App { // 【修改】FocusNoteApp -> FocusOneApp
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class FloatingPanel: NSPanel {
    let fullSize = NSSize(width: 350, height: 600)
    let miniSize = NSSize(width: 220, height: 200)
    let dragZoneHeight: CGFloat = 25
    
    var isMiniMode = false
    var isModalOpen = false
    var expandTimer: Timer?
    var collapseTimer: Timer?
    var savedMiniOrigin: NSPoint?
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView], backing: backing, defer: flag)
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = false
        self.hasShadow = false
        toggleWindowButtons(visible: true)
    }
    
    func toggleWindowButtons(visible: Bool) {
        self.standardWindowButton(.closeButton)?.isHidden = !visible
        self.standardWindowButton(.miniaturizeButton)?.isHidden = !visible
        self.standardWindowButton(.zoomButton)?.isHidden = !visible
    }
    
    func setupTrackingArea() {
        guard let view = self.contentView else { return }
        for area in view.trackingAreas { view.removeTrackingArea(area) }
        let trackingArea = NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect, .assumeInside], owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea)
    }
    
    func enterMiniMode() {
        if isModalOpen { return }
        if isMiniMode { return }
        isMiniMode = true
        expandTimer?.invalidate()
        toggleWindowButtons(visible: false)
        
        guard let screen = self.screen else { return }
        let screenFrame = screen.visibleFrame
        let targetOrigin: NSPoint
        if let saved = savedMiniOrigin { targetOrigin = saved }
        else { targetOrigin = NSPoint(x: screenFrame.maxX - miniSize.width - 10, y: screenFrame.minY + (screenFrame.height * 0.7)) }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            var newFrame = self.frame
            newFrame.size = miniSize
            newFrame.origin = targetOrigin
            self.animator().setFrame(newFrame, display: true)
        }
        NotificationCenter.default.post(name: NSNotification.Name("CollapseWindow"), object: nil)
    }
    
    func expandToFullMode() {
        if !isMiniMode { return }
        self.savedMiniOrigin = self.frame.origin
        isMiniMode = false
        collapseTimer?.invalidate()
        toggleWindowButtons(visible: true)
        NotificationCenter.default.post(name: NSNotification.Name("ExpandWindow"), object: nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            var newFrame = self.frame
            let currentMaxX = newFrame.maxX
            newFrame.size = fullSize
            newFrame.origin.x = currentMaxX - fullSize.width
            if let screen = self.screen, newFrame.minX < screen.visibleFrame.minX { newFrame.origin.x = screen.visibleFrame.minX + 20 }
            self.animator().setFrame(newFrame, display: true)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        if !isMiniMode { return }
        let mouseLoc = event.locationInWindow
        if mouseLoc.y > (self.frame.height - dragZoneHeight) { expandTimer?.invalidate(); expandTimer = nil }
        else { if expandTimer == nil { expandTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in self?.expandToFullMode() } } }
    }
    
    override func mouseEntered(with event: NSEvent) { if isMiniMode { collapseTimer?.invalidate(); expandTimer?.invalidate(); self.mouseMoved(with: event) } else { collapseTimer?.invalidate() } }
    override func mouseExited(with event: NSEvent) {
        expandTimer?.invalidate(); expandTimer = nil
        if isModalOpen { return }
        if !isMiniMode {
            collapseTimer?.invalidate()
            collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if !NSPointInRect(NSEvent.mouseLocation, self.frame) && !self.isModalOpen { self.enterMiniMode() }
            }
        }
    }
    override func mouseDragged(with event: NSEvent) { super.mouseDragged(with: event); expandTimer?.invalidate(); expandTimer = nil; collapseTimer?.invalidate() }
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingPanel: FloatingPanel!
    var contentViewModel: TaskManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        floatingPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 350, height: 600), backing: .buffered, defer: false)
        let model = TaskManager()
        self.contentViewModel = model
        let contentView = ContentView(manager: model)
        floatingPanel.contentView = NSHostingView(rootView: contentView)
        floatingPanel.center()
        floatingPanel.makeKeyAndOrderFront(nil)
        floatingPanel.setupTrackingArea()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("EnterMiniMode"), object: nil, queue: .main) { _ in self.floatingPanel.enterMiniMode() }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ModalOpened"), object: nil, queue: .main) { _ in self.floatingPanel.isModalOpen = true; self.floatingPanel.collapseTimer?.invalidate() }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ModalClosed"), object: nil, queue: .main) { _ in self.floatingPanel.isModalOpen = false; if !NSPointInRect(NSEvent.mouseLocation, self.floatingPanel.frame) { self.floatingPanel.mouseExited(with: NSEvent()) } }
    }
    func applicationWillTerminate(_ notification: Notification) { contentViewModel?.saveData() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { if !flag { floatingPanel.makeKeyAndOrderFront(nil) }; return true }
}
