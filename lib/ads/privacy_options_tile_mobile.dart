import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'ad_service.dart';

class PrivacyOptionsTile extends StatefulWidget {
  const PrivacyOptionsTile({super.key});

  @override
  State<PrivacyOptionsTile> createState() => _PrivacyOptionsTileState();
}

class _PrivacyOptionsTileState extends State<PrivacyOptionsTile> {
  bool _loading = true;
  bool _required = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await AdService.initialize();
    if (!mounted) return;
    setState(() {
      _required = AdService.privacyOptionsRequired;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_required) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.privacyChoices),
          subtitle: Text(l10n.privacyChoicesBody),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            await AdService.showPrivacyOptions();
            await _refresh();
          },
        ),
      ],
    );
  }
}
