import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 设置窗口最小尺寸
    self.minSize = NSSize(width: 1000, height: 600)
    
    // 设置窗口标题
    self.title = "FlutterPassword"
    
    // 设置窗口样式
    self.titlebarAppearsTransparent = false
    self.titleVisibility = .visible

    super.awakeFromNib()
  }
}
