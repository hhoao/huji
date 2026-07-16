import 'package:flutter/material.dart';

/// Converts a global (screen) pointer position to [RelativeRect] for [showMenu].
///
/// [showMenu] expects coordinates relative to the overlay, not raw
/// [TapDownDetails.globalPosition] values.
RelativeRect contextMenuPositionForGlobal(
  BuildContext context,
  Offset globalPosition, {
  bool rootOverlay = true,
}) {
  final overlay = Overlay.of(context, rootOverlay: rootOverlay)
      .context
      .findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(globalPosition);
  return RelativeRect.fromRect(
    Rect.fromLTWH(local.dx, local.dy, 0, 0),
    Offset.zero & overlay.size,
  );
}

/// Resolves a right-click position for [showSidebarActionMenu] from the
/// widget that owns [context].
Offset contextMenuGlobalPosition(
  BuildContext context,
  TapDownDetails details,
) {
  assert(context.mounted);
  return details.globalPosition;
}
