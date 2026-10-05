import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Line icons copied from the mockup's inline SVGs (24×24 viewBox, stroked).
enum AppIcon {
  settings(
    '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  ),
  timer('<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 1.5M9.5 2.5h5"/>'),
  calendar('<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>'),
  sliders('<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>'),
  clock('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>'),
  bolt('<path d="M13 2.8 5.5 13h5.8l-.8 8.2L18.5 11h-5.8z"/>'),
  drop('<path d="M12 3.2c3.3 4 6 7.6 6 10.8a6 6 0 0 1-12 0c0-3.2 2.7-6.8 6-10.8z"/>'),
  dropDetail(
    '<path d="M12 3.2c3.3 4 6 7.6 6 10.8a6 6 0 0 1-12 0c0-3.2 2.7-6.8 6-10.8z"/><path d="M9.2 14.6a2.9 2.9 0 0 0 2.6 2.6"/>',
  ),
  flame(
    '<path d="M12 2.8c.6 3.2 4.8 5.3 4.8 10.2a4.8 4.8 0 0 1-9.6 0c0-2.3 1.2-3.8 2.4-4.8.1 1.6.9 2.7 2 3.1-.6-2.9-.3-5.6.4-8.5z"/>',
  ),
  check('<path d="M5 12.5 10 17 19 7.5"/>'),
  info('<circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.6v.1"/>'),
  chevronRight('<path d="M9 6l6 6-6 6"/>'),
  back('<path d="M15 6l-6 6 6 6"/>');

  const AppIcon(this.paths);
  final String paths;
}

class AppIconView extends StatelessWidget {
  const AppIconView(this.icon, {super.key, this.size = 22, this.color, this.strokeWidth = 1.9});

  final AppIcon icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF1A2A20);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
      'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">${icon.paths}</svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c),
    );
  }
}
