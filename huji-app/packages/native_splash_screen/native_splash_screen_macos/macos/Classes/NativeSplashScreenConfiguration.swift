public protocol NativeSplashScreenConfigurationProvider {
    // Window Properties
    var windowWidth: Int { get }
    var windowHeight: Int { get }
    var windowTitle: String { get }

    // Animation Properties
    var withAnimation: Bool { get }

    // Image Properties
    var imageFileName: String { get } // Image file name in resources
    var imageWidth: Int { get } // Image width
    var imageHeight: Int { get } // Image height
}
