import 'package:flutter/material.dart';

@immutable
class HorarioTheme extends ThemeExtension<HorarioTheme> {
  final Color livreBackground;
  final Color livreText;

  final Color ocupadoBackground;
  final Color ocupadoText;

  final Color passadoBackground;
  final Color passadoText;

  final Color selecionadoBackground;
  final Color selecionadoText;

  const HorarioTheme({
    required this.livreBackground,
    required this.livreText,
    required this.ocupadoBackground,
    required this.ocupadoText,
    required this.passadoBackground,
    required this.passadoText,
    required this.selecionadoBackground,
    required this.selecionadoText,
  });

  @override
  HorarioTheme copyWith({
    Color? livreBackground,
    Color? livreText,
    Color? ocupadoBackground,
    Color? ocupadoText,
    Color? passadoBackground,
    Color? passadoText,
    Color? selecionadoBackground,
    Color? selecionadoText,
  }) {
    return HorarioTheme(
      livreBackground: livreBackground ?? this.livreBackground,
      livreText: livreText ?? this.livreText,
      ocupadoBackground: ocupadoBackground ?? this.ocupadoBackground,
      ocupadoText: ocupadoText ?? this.ocupadoText,
      passadoBackground: passadoBackground ?? this.passadoBackground,
      passadoText: passadoText ?? this.passadoText,
      selecionadoBackground: selecionadoBackground ?? this.selecionadoBackground,
      selecionadoText: selecionadoText ?? this.selecionadoText,
    );
  }

  @override
  HorarioTheme lerp(ThemeExtension<HorarioTheme>? other, double t) {
    if (other is! HorarioTheme) return this;

    return HorarioTheme(
      livreBackground: Color.lerp(livreBackground, other.livreBackground, t)!,
      livreText: Color.lerp(livreText, other.livreText, t)!,
      ocupadoBackground:
          Color.lerp(ocupadoBackground, other.ocupadoBackground, t)!,
      ocupadoText: Color.lerp(ocupadoText, other.ocupadoText, t)!,
      passadoBackground:
          Color.lerp(passadoBackground, other.passadoBackground, t)!,
      passadoText: Color.lerp(passadoText, other.passadoText, t)!,
      selecionadoBackground:
          Color.lerp(selecionadoBackground, other.selecionadoBackground, t)!,
      selecionadoText: Color.lerp(selecionadoText, other.selecionadoText, t)!,
    );
  }
}
