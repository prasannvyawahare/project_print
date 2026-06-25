import 'package:flutter/material.dart';

/// Shared top app bar used across the whole app.
///
/// Two modes:
/// * Brand mode (default, [title] == null) — shows the PrintHub logo + wordmark
///   on the left. Used on the home dashboard.
/// * Title mode ([title] != null) — shows an optional back button and a page
///   title. Used on inner/detail screens.
///
/// A notification bell (with optional unread badge) is shown on the right in
/// both modes when [showNotification] is true.
class PrintHubAppBar extends StatelessWidget {
  const PrintHubAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
    this.centerTitle = false,
    this.showNotification = true,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.actions = const <Widget>[],
  });

  /// Page title. When null, the brand logo + "PrintHub" wordmark is shown.
  final String? title;

  /// Whether to show a leading back button.
  final bool showBack;

  /// Custom back handler. Defaults to [Navigator.maybePop].
  final VoidCallback? onBack;

  /// Center the title (title mode only).
  final bool centerTitle;

  /// Whether to show the trailing notification bell.
  final bool showNotification;

  /// Unread notification count. The badge is hidden when this is 0.
  final int notificationCount;

  /// Tap handler for the notification bell. Defaults to a "no notifications"
  /// snackbar.
  final VoidCallback? onNotificationTap;

  /// Extra trailing actions placed before the notification bell.
  final List<Widget> actions;

  static const Color _accent = Color(0xFF2563EB);
  static const Color _titleColor = Color(0xFF1B1B2F);

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthScale = (size.width / 390).clamp(0.82, 1.0);
    final heightScale = (size.height / 844).clamp(0.82, 1.0);
    return (widthScale * 0.7 + heightScale * 0.3).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    double r(double v) => v * scale;

    final isBrand = title == null;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        showBack ? r(4) : r(18),
        r(8),
        r(8),
        r(10),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: r(20),
              ),
              color: _titleColor,
            ),
          if (isBrand) ...[
            Container(
              width: r(38),
              height: r(38),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(r(11)),
              ),
              child: Icon(
                Icons.print_rounded,
                color: Colors.white,
                size: r(22),
              ),
            ),
            SizedBox(width: r(10)),
            Text(
              'PrintHub',
              style: TextStyle(
                fontSize: r(22),
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
            const Spacer(),
          ] else
            Expanded(
              child: Align(
                alignment:
                    centerTitle ? Alignment.center : Alignment.centerLeft,
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: r(19),
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
              ),
            ),
          ...actions,
          if (showNotification)
            _NotificationBell(
              scale: scale,
              count: notificationCount,
              onTap: onNotificationTap ??
                  () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(content: Text('No new notifications')),
                      );
                  },
            ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.scale,
    required this.count,
    required this.onTap,
  });

  final double scale;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double r(double v) => v * scale;

    return Tooltip(
      message: 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(
              Icons.notifications_none_rounded,
              size: r(26),
              color: PrintHubAppBar._titleColor,
            ),
          ),
          if (count > 0)
            Positioned(
              right: r(6),
              top: r(4),
              child: Container(
                padding: EdgeInsets.all(r(4)),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: r(16),
                  minHeight: r(16),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r(10),
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
