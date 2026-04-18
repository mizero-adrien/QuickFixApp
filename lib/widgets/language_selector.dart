import 'package:flutter/material.dart';
import 'package:quickfix/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopupMenuButton<Locale>(
      onSelected: (Locale locale) {
        LocaleProvider.changeLocale(locale);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Text(localizations.english),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('fr'),
          child: Text(localizations.french),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('rw'),
          child: Text(localizations.kinyarwanda),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.language, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              localizations.language,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}