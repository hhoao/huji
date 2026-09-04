/// Defines the type of animation used to close the splash screen.
enum CloseAnimation {
  /// Closes the splash screen like a normal window, instantly without any animation.
  none,

  /// Gradually decreases the window's opacity until it becomes fully transparent.
  fade,

  /// Slides the splash screen upwards while fading it out.
  slideUpFade,

  /// Slides the splash screen downwards while fading it out.
  slideDownFade,
}

/// Extension to convert [CloseAnimation] to the corresponding native animation name.
extension NativeName on CloseAnimation {
  /// Returns the native string name used for platform-specific animation handling.
  String get name {
    switch (this) {
      case CloseAnimation.none:
        return '';
      case CloseAnimation.fade:
        return 'fade';
      case CloseAnimation.slideUpFade:
        return 'slide_up_fade';
      case CloseAnimation.slideDownFade:
        return 'slide_down_fade';
    }
  }
}
