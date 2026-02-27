import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import '../providers/persistence_provider.dart';
import '../models/payment_method.dart';
import '../l10n/app_l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final defaultAlarmTime =
        settings[SettingsNotifier.keyDefaultAlarmTime] as String;
    final selectedPayments = List<String>.from(
      settings[SettingsNotifier.keySelectedPayments] ?? [],
    );
    final defaultBudget = settings[SettingsNotifier.keyDefaultBudget] as double;
    final themeStr =
        settings[SettingsNotifier.keyThemeMode] as String? ?? 'dark';

    final paymentMethods = ref.watch(paymentMethodsProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Option
          ListTile(
            title: Text(
              l10n.settingsTheme,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              themeStr == 'dark'
                  ? l10n.settingsThemeDark
                  : l10n.settingsThemeLight,
            ),
            trailing: Icon(
              themeStr == 'dark' ? Icons.dark_mode : Icons.light_mode,
              color: themeStr == 'dark'
                  ? const Color(0xFF00E5FF)
                  : Colors.orange,
            ),
            onTap: () {
              final newTheme = themeStr == 'dark' ? 'light' : 'dark';
              ref.read(settingsProvider.notifier).updateThemeMode(newTheme);
            },
          ),
          const Divider(),

          // Language Option
          ListTile(
            title: Text(
              l10n.settingsLanguage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(l10n.isEn ? 'English' : '繁體中文'),
            trailing: const Icon(Icons.language),
            onTap: () {
              final newLang = l10n.isEn ? 'zh' : 'en';
              ref.read(settingsProvider.notifier).updateLanguage(newLang);
            },
          ),
          const Divider(),

          // Default Budget
          ListTile(
            title: Text(
              l10n.settingsDefaultBudget,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              defaultBudget >= 9999.0
                  ? l10n.budgetUnlimited
                  : 'HK\$ ${defaultBudget.toStringAsFixed(0)}',
            ),
            trailing: const Icon(Icons.account_balance_wallet_outlined),
            onTap: () async {
              final controller = TextEditingController(
                text: defaultBudget >= 9999.0
                    ? ''
                    : defaultBudget.toStringAsFixed(0),
              );
              final result = await showDialog<double>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.editDefaultBudget),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: l10n.searchBudgetHint,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) {
                          Navigator.pop(context, 9999.0);
                        } else {
                          final val = double.tryParse(text);
                          Navigator.pop(context, val ?? 9999.0);
                        }
                      },
                      child: Text(l10n.confirm),
                    ),
                  ],
                ),
              );
              if (result != null) {
                ref.read(settingsProvider.notifier).updateDefaultBudget(result);
              }
            },
          ),
          const Divider(),

          // Default Alarm Time
          ListTile(
            title: Text(
              l10n.settingsDefaultAlarm,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(defaultAlarmTime),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final parts = defaultAlarmTime.split(':');
              final time = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
              final selected = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (selected != null) {
                final formattedTime =
                    '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                ref
                    .read(settingsProvider.notifier)
                    .updateDefaultAlarmTime(formattedTime);
              }
            },
          ),
          const Divider(),

          // Payment Methods
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              l10n.settingsSelectPayments,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),

          _buildPaymentCategory(
            context,
            l10n.eWallets,
            paymentMethods.where((p) => p.type == 'e_wallet').toList(),
            selectedPayments,
            ref,
            l10n,
          ),
          _buildPaymentCategory(
            context,
            l10n.creditCards,
            paymentMethods.where((p) => p.type == 'credit_card').toList(),
            selectedPayments,
            ref,
            l10n,
          ),
          _buildPaymentCategory(
            context,
            l10n.memberships,
            paymentMethods.where((p) => p.type == 'membership').toList(),
            selectedPayments,
            ref,
            l10n,
          ),
          _buildPaymentCategory(
            context,
            l10n.identities,
            paymentMethods
                .where((p) => p.type == 'identity' || p.type == 'octopus')
                .toList(),
            selectedPayments,
            ref,
            l10n,
          ),
        ],
      ),
    );
  }

  Color _getPaymentTypeColor(String type) {
    switch (type) {
      case 'e_wallet':
        return Colors.teal.shade700;
      case 'credit_card':
        return Colors.amber.shade700;
      case 'membership':
        return Colors.indigo.shade700;
      case 'identity':
      case 'octopus':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade800;
    }
  }

  Widget _buildPaymentCategory(
    BuildContext context,
    String title,
    List<PaymentMethod> methods,
    List<String> selectedPayments,
    WidgetRef ref,
    AppL10n l10n,
  ) {
    if (methods.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          children: methods.map((pm) {
            final isSelected = selectedPayments.contains(pm.id);
            final typeColor = _getPaymentTypeColor(pm.type);

            return Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? typeColor
                    : typeColor.withValues(alpha: 0.1),
                border: Border.all(color: typeColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    final list = List<String>.from(selectedPayments);
                    if (!isSelected) {
                      list.add(pm.id);
                    } else {
                      list.remove(pm.id);
                    }
                    ref
                        .read(settingsProvider.notifier)
                        .updateSelectedPayments(list);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          l10n.trShopName(pm.nameZh, pm.nameEn),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (pm.descriptionZh != null ||
                            pm.descriptionEn != null) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: l10n.trDescription(
                              pm.descriptionZh,
                              pm.descriptionEn,
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            showDuration: const Duration(seconds: 3),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.grey[400]
                                        : Colors.black54),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
