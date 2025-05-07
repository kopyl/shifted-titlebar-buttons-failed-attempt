import Cocoa
import SwiftUI

class WindowConfig {
    static let width: CGFloat = 659
    static let height: CGFloat = 400
    static let sideBarTopPadding: CGFloat = 43
}

enum SidebarItem: String, CaseIterable {
    case shortcut = "Shortcut"
    case appearance = "Appearance"
    
    var viewController: NSViewController {
        switch self {
        case .shortcut:
            return ShortcutViewController()
        case .appearance:
            return AppearanceViewController()
        }
    }
}

protocol SidebarSelectionDelegate: AnyObject {
    func didSelectSidebarItem(_ item: SidebarItem)
}

class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    weak var delegate: SidebarSelectionDelegate?
    
    private let tableView = NSTableView()
    private let items = SidebarItem.allCases

    override func loadView() {
        self.view = NSView()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        tableView.addTableColumn(column)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.focusRingType = .none
        
        DispatchQueue.main.async {
            self.tableView.selectRowIndexes([0], byExtendingSelection: false)
        }
        
        view.addSubview(tableView)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return NSTextField(labelWithString: items[row].rawValue)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedIndex = tableView.selectedRow
        guard selectedIndex >= 0 else { return }
        delegate?.didSelectSidebarItem(items[selectedIndex])
    }
}

class SettingsView: NSView {
    let rootView: AnyView

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect) {
        fatalError("Use init(view:) instead")
    }

    init<V: View>(view: V) {
        self.rootView = AnyView(view)
        super.init(frame: .zero)
        setupView()
    }

    private func setupView() {
        let hostingView = NSHostingView(rootView: rootView)
        addSubview(hostingView)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

struct ShortcutSettingsView: View {
    var body: some View {
        VStack {
            Text("Shortcut Settings")
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        VStack {
            Text("Appearance Settings")
        }
        .frame(minWidth: 400, minHeight: 500)
        
    }
}

class ShortcutViewController: NSViewController {
    override func loadView() {
        self.view = SettingsView(view: ShortcutSettingsView())
    }
}

class AppearanceViewController: NSViewController {
    override func loadView() {
        self.view = SettingsView(view: AppearanceSettingsView())
    }
}

class SplitViewController: NSSplitViewController, SidebarSelectionDelegate {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height))
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarVC = SidebarViewController()
        sidebarVC.delegate = self

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        addSplitViewItem(sidebarItem)
        
        let detailItem = NSSplitViewItem(viewController: SidebarItem.shortcut.viewController)
        addSplitViewItem(detailItem)
    }

    func didSelectSidebarItem(_ item: SidebarItem) {
        removeSplitViewItem(splitViewItems[1])
        let newDetailItem = NSSplitViewItem(viewController: item.viewController)
        addSplitViewItem(newDetailItem)
    }
}

var mainWindow: NSWindow?
var mainWindowController: SettingsWindowController?

func addPaddingToWindowButtons(leading: CGFloat, top: CGFloat) {
    mainWindow?.standardWindowButton(.miniaturizeButton)?.frame.origin.y -= top
    mainWindow?.standardWindowButton(.closeButton)?.frame.origin.y -= top
    mainWindow?.standardWindowButton(.zoomButton)?.frame.origin.y -= top
    
    mainWindow?.standardWindowButton(.miniaturizeButton)?.frame.origin.x += leading
    mainWindow?.standardWindowButton(.closeButton)?.frame.origin.x += leading
    mainWindow?.standardWindowButton(.zoomButton)?.frame.origin.x += leading
    
    let buttonContainer = mainWindow?.standardWindowButton(.closeButton)?.superview
    
    for subview in buttonContainer?.subviews ?? [] where subview is NSTextField {
        subview.frame.origin.y -= top
    }
}

class SettingsWindowController: NSWindowController {
    override init(window: NSWindow?) {
        super.init(window: window)
        
        NotificationCenter.default.addObserver(
                self,
           selector: #selector(windowDidResize(_:)),
           name: NSWindow.didResizeNotification,
           object: mainWindow
        )
    }
    
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }
    
    @objc func windowDidResize(_ notification: Notification) {
            addPaddingToWindowButtons(leading: 12, top: 12)
    }
    
    deinit {
            NotificationCenter.default.removeObserver(
                self,
            name: NSWindow.didResizeNotification,
            object: self.window
        )
    }
}

func createMainWindow() {
    mainWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height),
        styleMask: [.titled, .closable, .fullSizeContentView],
        backing: .buffered, defer: false
    )
    mainWindow?.center()
    mainWindow?.contentViewController = SplitViewController()
    
    mainWindow?.titlebarAppearsTransparent = true
    mainWindow?.titleVisibility = .hidden
    
    mainWindowController = SettingsWindowController(window: mainWindow)
    mainWindow?.makeKeyAndOrderFront(nil)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createMainWindow()
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

let app = Application.shared
let delegate = AppDelegate()
app.delegate = delegate

app.run()
