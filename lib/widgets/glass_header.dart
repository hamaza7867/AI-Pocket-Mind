import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class GlassHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final VoidCallback? onMenuPressed;

  const GlassHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: FuturisticTheme.getBackgroundColor(isDark).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: FuturisticTheme.getAccentColor(isDark).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context) && onMenuPressed == null)
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: FuturisticTheme.getAccentColor(isDark)),
              onPressed: () => Navigator.pop(context),
            ),
          if (onMenuPressed != null)
            IconButton(
              icon: Icon(Icons.grid_view_rounded,
                  color: FuturisticTheme.getAccentColor(isDark)),
              onPressed: onMenuPressed,
            ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: FuturisticTheme.getTitleStyle(isDark),
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: FuturisticTheme.getAccentColor(isDark),
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          ...actions,
        ],
      ),
    );
  }
}
