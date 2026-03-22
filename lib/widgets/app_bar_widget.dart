import 'package:flutter/material.dart';
import 'package:alagahub/utils/app_theme.dart';

PreferredSizeWidget buildAppBar(BuildContext context, String title,
    {List<Widget>? actions, bool showBack = true}) {
  return AppBar(
    title: title.isNotEmpty ? Text(title) : null,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null,
    automaticallyImplyLeading: showBack,
    actions: actions,
    elevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppTheme.divider),
    ),
  );
}
