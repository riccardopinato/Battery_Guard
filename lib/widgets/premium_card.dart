import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/app_controller.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final premium = controller.premium;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.workspace_premium_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.proTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        premium.isPro ? l10n.proOwned : l10n.proSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (premium.isPro)
                  Icon(Icons.verified_rounded, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 14),
            _Feature(text: l10n.proFeatureNoAds),
            const SizedBox(height: 8),
            _Feature(text: l10n.proFeatureHealth),
            const SizedBox(height: 8),
            _Feature(text: l10n.proFeatureDoctor),
            const SizedBox(height: 8),
            _Feature(text: l10n.proFeatureRanking),
            const SizedBox(height: 8),
            _Feature(text: l10n.proFeatureStress),
            const SizedBox(height: 8),
            _Feature(text: l10n.proFeatureCurves),
            const SizedBox(height: 8),
            _Feature(text: l10n.proFeatureInsights30),
            if (!premium.isPro) ...[
              const SizedBox(height: 16),
              if (!premium.storeAvailable &&
                  !premium.loading &&
                  !premium.localTestUnlockAvailable)
                Text(
                  l10n.storeUnavailable,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              if (premium.error case final error?) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: premium.canUnlock
                    ? () async {
                        final started = await premium.buy();
                        if (!context.mounted || started) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.purchaseError)),
                        );
                      }
                    : null,
                icon: premium.loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: Text(
                  premium.localizedPrice == null
                      ? l10n.unlockPro
                      : l10n.unlockForPrice(premium.localizedPrice!),
                ),
              ),
              TextButton(
                onPressed:
                    premium.storeAvailable ? premium.restore : null,
                child: Text(l10n.restorePurchases),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
