import AppKit
import Cocoa

public class NativeSplashScreen {
    // MARK: - Public Configuration

    public static var configurationProvider: NativeSplashScreenConfigurationProvider?
    
    // MARK: - Private State

    private static var splashWindow: NSWindow?
    private static var isSplashShown: Bool = false

    // Overlay mode: the splash is a subview stacked over the Flutter view inside
    // the app's own window, instead of a separate [splashWindow]. Only one of the
    // two is ever active. See attachOverlay(to:).
    private static var overlayView: NSView?

    // MARK: - Public Methods

    public static func show() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { show() }
            return
        }
        
        guard !isSplashShown else { return }
        
        guard let config = configurationProvider else {
            print("NativeSplashScreen: ERROR - ConfigurationProvider not set. Splash screen cannot be shown.")
            return
        }
        
        guard config.windowWidth > 0, config.windowHeight > 0 else {
            print("NativeSplashScreen: WARNING - Invalid window dimensions provided (<=0). Splash not shown.")
            return
        }
        
        let window = createSplashWindow(config: config)

        if let image = loadImageFromResources(fileName: config.imageFileName) {
            let imageView = createImageView(with: image, config: config, windowSize: window.frame.size)
            window.contentView?.addSubview(imageView)
        } else {
            print("NativeSplashScreen: WARNING - Failed to load image '\(config.imageFileName)' from resources. Window will be blank.")
        }

        Self.splashWindow = window
        displaySplashWindow(window, animated: config.withAnimation)
        isSplashShown = true
    }
    
    /// Overlay mode: stacks the splash over the Flutter view inside the app's own
    /// [window] instead of showing a separate splash window. Call this from
    /// MainFlutterWindow once the contentView exists, in place of `show()`.
    /// Dismiss it from Dart via close(). Avoids a second window that has to be
    /// positioned/raised independently of the main window.
    public static func attachOverlay(to window: NSWindow) {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { attachOverlay(to: window) }
            return
        }

        guard !isSplashShown else { return }

        guard let config = configurationProvider else {
            print("NativeSplashScreen: ERROR - ConfigurationProvider not set. Overlay cannot be shown.")
            return
        }

        guard let contentView = window.contentView else {
            print("NativeSplashScreen: ERROR - window has no contentView. Overlay cannot be shown.")
            return
        }

        let overlay = NSView(frame: contentView.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.wantsLayer = true
        // Opaque cover so the Flutter view does not show through during warmup.
        overlay.layer?.backgroundColor = NSColor.white.cgColor

        if let image = loadImageFromResources(fileName: config.imageFileName) {
            let imageView = createImageView(with: image, config: config, windowSize: contentView.bounds.size)
            // Keep the logo centered as the window resizes.
            imageView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
            overlay.addSubview(imageView)
        } else {
            print("NativeSplashScreen: WARNING - Failed to load image '\(config.imageFileName)' from resources. Overlay will be blank.")
        }

        contentView.addSubview(overlay) // on top of the Flutter view
        Self.overlayView = overlay
        isSplashShown = true
    }

    /// Re-center the separate splash window and raise it above the main window
    /// after the main maps. No-op in overlay mode (already stacked in-window).
    public static func ensureOnTop() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { ensureOnTop() }
            return
        }

        if overlayView != nil {
            return
        }

        guard isSplashShown, let window = splashWindow else { return }

        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.visibleFrame
            let size = window.frame.size
            let xPos = (screenRect.width - size.width) / 2.0 + screenRect.origin.x
            let yPos = (screenRect.height - size.height) / 2.0 + screenRect.origin.y
            window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }

        window.level = NSWindow.Level.floating
        window.orderFront(nil)
    }

    public static func close(effect: String = "") {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { close(effect: effect) }
            return
        }

        // Overlay mode: fade + remove the in-window overlay instead of a window.
        if let overlay = overlayView {
            closeOverlay(overlay, effect: effect)
            return
        }

        guard isSplashShown, let window = splashWindow else { return }

        let fadeDuration = 0.3
        let slideDistance: CGFloat = 50.0
        
        let completionHandler = {
            window.orderOut(nil)
            Self.splashWindow = nil // Allow ARC to deallocate
            Self.isSplashShown = false
        }
        
        if effect.isEmpty {
            completionHandler()
            return
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = fadeDuration
            switch effect.lowercased() {
            case "fade":
                window.animator().alphaValue = 0.0
            case "slide_up_fade":
                window.animator().alphaValue = 0.0
                var newFrame = window.frame
                newFrame.origin.y += slideDistance
                window.animator().setFrame(newFrame, display: true, animate: true)
            case "slide_down_fade":
                window.animator().alphaValue = 0.0
                var newFrame = window.frame
                newFrame.origin.y -= slideDistance
                window.animator().setFrame(newFrame, display: true, animate: true)
            default:
                window.animator().alphaValue = 0.0
            }
        }, completionHandler: completionHandler)
    }
    
    // MARK: - Private Helper Methods

    private static func closeOverlay(_ overlay: NSView, effect: String) {
        let completionHandler = {
            overlay.removeFromSuperview()
            Self.overlayView = nil
            Self.isSplashShown = false
        }
        if effect.isEmpty {
            completionHandler()
            return
        }
        // Any non-empty effect maps to a fade; the slide variants move a window,
        // which an in-window overlay has no equivalent for.
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            overlay.animator().alphaValue = 0.0
        }, completionHandler: completionHandler)
    }

    private static func createSplashWindow(config: NativeSplashScreenConfigurationProvider) -> NSWindow {
        let contentRect = NSRect(x: 0, y: 0, width: CGFloat(config.windowWidth), height: CGFloat(config.windowHeight))
        
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level.floating
        window.hasShadow = false
        window.title = config.windowTitle // Important for accessibility

        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.visibleFrame
            let xPos = (screenRect.width - contentRect.width) / 2.0 + screenRect.origin.x
            let yPos = (screenRect.height - contentRect.height) / 2.0 + screenRect.origin.y
            window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
        
        // Always assign a new content view for custom drawing or subviews.
        window.contentView = NSView(frame: contentRect)
        return window
    }

    private static func loadImageFromResources(fileName: String) -> NSImage? {
        let imageName = (fileName as NSString).deletingPathExtension

        // NSImage(named:) automatically handles Retina (@2x) vs. standard (@1x) resolution.
        // It looks for the image inside the compiled Assets.xcassets catalog.
        if let image = NSImage(named: imageName) {
            return image
        } else {
            print("NativeSplashScreen: ERROR - Could not load image named '\(imageName)' from the asset catalog. Make sure it's included in the target's build phase.")
            return nil
        }
    }

    private static func createImageView(with image: NSImage, config: NativeSplashScreenConfigurationProvider, windowSize: NSSize) -> NSImageView {
        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown // Sensible default

        // Use configured image dimensions (logical size) instead of actual image dimensions
        let imageWidth = CGFloat(config.imageWidth)
        let imageHeight = CGFloat(config.imageHeight)
        
        let imageX = (windowSize.width - imageWidth) / 2.0
        let imageY = (windowSize.height - imageHeight) / 2.0
        
        imageView.frame = NSRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
        return imageView
    }
    
    private static func displaySplashWindow(_ window: NSWindow, animated: Bool) {
        if animated {
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3 // Standard fade duration
                window.animator().alphaValue = 1.0
            }, completionHandler: nil)
        } else {
            window.alphaValue = 1.0
            window.makeKeyAndOrderFront(nil)
        }
    }
}
