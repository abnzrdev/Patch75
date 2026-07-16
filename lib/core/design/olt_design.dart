import 'package:flutter/material.dart';

abstract final class OltColors {
  static const background = Color(0xFF090B09);
  static const surface = Color(0xFF101310);
  static const raised = Color(0xFF171B17);
  static const border = Color(0xFF3D463D);
  static const muted = Color(0xFFA7B0A7);
  static const foreground = Color(0xFFF2F3ED);
  static const signal = Color(0xFFB7FF3C);
  static const danger = Color(0xFFFF6B57);
}

abstract final class OltSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x6 = 24.0;
}

ThemeData buildOltTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: OltColors.background,
  colorScheme: const ColorScheme.dark(
    primary: OltColors.signal,
    onPrimary: OltColors.background,
    surface: OltColors.surface,
    onSurface: OltColors.foreground,
    error: OltColors.danger,
  ),
  fontFamily: 'monospace',
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: OltColors.signal,
    selectionColor: Color(0x557DBB1E),
  ),
  focusColor: OltColors.signal,
  splashFactory: NoSplash.splashFactory,
  visualDensity: VisualDensity.compact,
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: OltColors.surface,
    indicatorColor: Color(0x337DBB1E),
    height: 64,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: OltColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: OltColors.signal, width: 2),
    ),
  ),
);

const microStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 10,
  height: 1.3,
  letterSpacing: 1.1,
  color: OltColors.muted,
);

class OltPanel extends StatelessWidget {
  const OltPanel({
    required this.label,
    required this.child,
    this.panelKey,
    super.key,
  });

  final String label;
  final Widget child;
  final Key? panelKey;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: panelKey,
    decoration: const BoxDecoration(
      color: OltColors.surface,
      border: Border.fromBorderSide(BorderSide(color: OltColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: OltSpace.x2),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: OltColors.border),
              left: BorderSide(color: OltColors.signal, width: 2),
            ),
          ),
          child: Text(
            label,
            style: microStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class OltButton extends StatelessWidget {
  const OltButton({
    required this.label,
    required this.onPressed,
    this.buttonKey,
    this.signal = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool signal;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: signal ? OltColors.signal : OltColors.foreground,
        side: BorderSide(color: signal ? OltColors.signal : OltColors.border),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: microStyle.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}
