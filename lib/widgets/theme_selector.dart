import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_salao_pro/theme/theme_notifier.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      child: DropdownButton<AppThemeMode>(
        value: themeNotifier.appThemeMode,
        underline: const SizedBox(),
        dropdownColor: bgColor,
        iconEnabledColor: textColor,
        style: TextStyle(color: textColor, fontSize: 15),
        isExpanded: true,
        items: const [
          DropdownMenuItem(
            value: AppThemeMode.system,
            child: Text('Automático'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.light,
            child: Text('Claro'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.dark,
            child: Text('Escuro'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            themeNotifier.setTheme(value);
          }
        },
      ),
    );
  }
}
