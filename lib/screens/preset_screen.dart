import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/discount_engine.dart';
import '../providers/persistence_provider.dart';
import '../providers/data_provider.dart';
import 'search_results_screen.dart';
import '../l10n/app_l10n.dart';

class PresetScreen extends ConsumerWidget {
  final Function(int) onNavigateToTab;
  final GlobalKey<NavigatorState> homeNavigatorKey;

  const PresetScreen({
    super.key,
    required this.onNavigateToTab,
    required this.homeNavigatorKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider);
    final shops = ref.watch(shopsProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.presetTitle)),
      body: presets.isEmpty
          ? Center(child: Text(l10n.presetEmpty))
          : ListView.builder(
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                final shop = shops.firstWhere(
                  (s) => s.id == preset.shopId,
                  orElse: () => shops.first,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    title: Text(
                      '${l10n.trShopName(shop.nameZh, shop.nameEn)} - HK\$${preset.amount.toStringAsFixed(0)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.deletePreset),
                            content: Text(l10n.confirmDeletePreset),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(presetsProvider.notifier)
                                      .deletePreset(preset.id);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  l10n.confirm,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      final currentInput = ref.read(userInputProvider);
                      ref
                          .read(userInputProvider.notifier)
                          .updateState(
                            currentInput.copyWith(
                              shopId: preset.shopId,
                              amount: preset.amount,
                            ),
                          );
                      onNavigateToTab(1); // Switch to Search Tab
                      homeNavigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (context) => const SearchResultsScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
