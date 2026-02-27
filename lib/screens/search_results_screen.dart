import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/discount_engine.dart';
import '../providers/persistence_provider.dart';
import '../models/persistence_models.dart';
import '../models/discount.dart';
import '../models/payment_method.dart';
import '../models/shop.dart';
import '../providers/data_provider.dart';
import '../l10n/app_l10n.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  bool _showAllShopDiscounts = true;
  bool _showIndividualProducts = true;

  void _savePreset(AppL10n l10n) {
    final input = ref.read(userInputProvider);
    if (input.shopId.isEmpty || input.amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.searchSelectShopFirst)));
      return;
    }
    final preset = PresetSearch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopId: input.shopId,
      amount: input.amount,
      createdAt: DateTime.now(),
    );
    ref.read(presetsProvider.notifier).savePreset(preset);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.maxPresetsReached)));
  }

  void _showAlarmDialog(Discount discount, DateTime date) async {
    final settings = ref.read(settingsProvider);
    final defaultTimeStr =
        settings[SettingsNotifier.keyDefaultAlarmTime] as String;
    final parts = defaultTimeStr.split(':');
    final defaultTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: defaultTime,
      );

      if (selectedTime != null) {
        final triggerTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        final reminder = AlarmReminder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          discountId: discount.id,
          shopId: ref.read(userInputProvider).shopId,
          triggerTime: triggerTime,
        );
        ref.read(remindersProvider.notifier).saveReminder(reminder);

        if (mounted) {
          final l10n = ref.read(l10nProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.savedToReminders)));
        }
      }
    }
  }

  String _getRelativeDateText(DateTime date, AppL10n l10n) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final diff = dateOnly.difference(todayOnly).inDays;

    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateTomorrow;
    return l10n.dateDaysLater(diff);
  }

  @override
  Widget build(BuildContext context) {
    final userInput = ref.watch(userInputProvider);
    final presets = ref.watch(presetsProvider);
    final groupedDiscounts = ref.watch(groupedDiscountsProvider);
    final l10n = ref.watch(l10nProvider);

    bool isSavedAsPreset = presets.any(
      (p) => p.shopId == userInput.shopId && p.amount == userInput.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchResults),
        actions: [
          // Show All Shop Discounts Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _showAllShopDiscounts,
                onChanged: (val) {
                  setState(() => _showAllShopDiscounts = val ?? true);
                },
              ),
              Tooltip(
                message: l10n.showAllDiscounts,
                child: Icon(
                  Icons.attach_money,
                  color: _showAllShopDiscounts ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Individual Products Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _showIndividualProducts,
                onChanged: (val) {
                  setState(() => _showIndividualProducts = val ?? true);
                },
              ),
              Tooltip(
                message: l10n.showIndividualProducts,
                child: Icon(
                  Icons.shopping_cart,
                  color: _showIndividualProducts ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isSavedAsPreset ? Icons.favorite : Icons.favorite_border,
            ),
            color: Theme.of(context).colorScheme.secondary,
            tooltip: l10n.saveToPreset,
            onPressed: () => _savePreset(l10n),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userInput.shopId.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.searchSelectShopFirst,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else if (groupedDiscounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.searchNoResults),
              )
            else
              _buildResultsList(
                groupedDiscounts,
                userInput,
                ref.watch(paymentMethodsProvider),
                ref.watch(shopsProvider),
                l10n,
              ),
          ],
        ),
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

  Widget _buildResultsList(
    Map<DateTime, List<CategorizedDiscount>> groupedDiscounts,
    UserInput userInput,
    List<PaymentMethod> paymentMethods,
    List<Shop> allShops,
    AppL10n l10n,
  ) {
    final sortedDates = groupedDiscounts.keys.toList()..sort();
    final dateFormatter = DateFormat(l10n.dateShortFormat);

    final activeShop = allShops.firstWhere(
      (s) => s.id == userInput.shopId,
      orElse: () => Shop(
        id: '',
        nameZh: l10n.shopUnknown,
        nameEn: l10n.shopUnknown,
        category: '',
      ),
    );

    final budgetText = userInput.amount >= 9999.0
        ? l10n.budgetUnlimited
        : 'HK\$${userInput.amount.toStringAsFixed(0)}';

    Widget buildDiscountTile(CategorizedDiscount catDiscount, DateTime date) {
      final discount = catDiscount.discount;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          l10n.trDiscountTitle(discount.titleZh, discount.titleEn),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (discount.requiredPaymentIds.isNotEmpty) ...[
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: discount.requiredPaymentIds.map((pid) {
                  final pm = paymentMethods.firstWhere(
                    (p) => p.id == pid,
                    orElse: () => PaymentMethod(
                      id: pid,
                      nameZh: pid,
                      nameEn: pid,
                      type: 'other',
                    ),
                  );
                  final pColor = _getPaymentTypeColor(pm.type);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.15),
                      border: Border.all(color: pColor, width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.trShopName(pm.nameZh, pm.nameEn),
                          style: TextStyle(
                            fontSize: 10,
                            color: pColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pm.descriptionZh != null ||
                            pm.descriptionEn != null) ...[
                          const SizedBox(width: 2),
                          Tooltip(
                            message: l10n.trDescription(
                              pm.descriptionZh,
                              pm.descriptionEn,
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            showDuration: const Duration(seconds: 3),
                            child: Icon(
                              Icons.help_outline,
                              size: 10,
                              color: pColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
            ],
            if (discount.schedule.endDate != null) ...[
              Builder(
                builder: (context) {
                  final endDate = discount.schedule.endDate!;
                  final today = DateTime.now();
                  final todayOnly = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );
                  final endOnly = DateTime(
                    endDate.year,
                    endDate.month,
                    endDate.day,
                  );
                  final diff = endOnly.difference(todayOnly).inDays;

                  bool isExpiringSoon = diff <= 1 && diff >= 0;
                  String expiryText = l10n.validUntil(
                    dateFormatter.format(endDate),
                  );
                  if (diff == 0) {
                    expiryText = l10n.validToday;
                  } else if (diff == 1) {
                    expiryText = l10n.validTomorrow;
                  }

                  return Text(
                    expiryText,
                    style: TextStyle(
                      color: isExpiringSoon ? Colors.redAccent : Colors.grey,
                      fontWeight: isExpiringSoon
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
            ],
            if (discount.conditions.minSpend > 0)
              Text(
                '${l10n.minSpendTitle}${discount.conditions.minSpend}',
                style: TextStyle(
                  color: discount.conditions.minSpend > userInput.amount
                      ? Colors.redAccent
                      : Colors.grey,
                ),
              ),
            if (discount.rewards.rate != null)
              Text(
                '${l10n.rewardRatePrefix}${(discount.rewards.rate! * 100).toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (discount.rewards.amount != null)
              Text(
                '${l10n.rewardAmountPrefix}${discount.rewards.amount}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.alarm_add, color: Colors.cyanAccent),
          tooltip: l10n.addToReminders,
          onPressed: () => _showAlarmDialog(discount, date),
        ),
      );
    }

    Widget buildCategoryFlexbox(
      String title,
      List<CategorizedDiscount> items,
      DateTime date,
    ) {
      if (items.isEmpty) return const SizedBox.shrink();

      if (title.isEmpty) {
        return Column(
          children: items
              .map((catDiscount) => buildDiscountTile(catDiscount, date))
              .toList(),
        );
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            ...items.map((catDiscount) => buildDiscountTile(catDiscount, date)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Target Summary Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Text(
                l10n.trShopName(activeShop.nameZh, activeShop.nameEn),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.budgetLabel}$budgetText',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),

        // Date Groups
        ...sortedDates.map((date) {
          final discounts = groupedDiscounts[date]!;

          final applicable = discounts
              .where((d) => d.status == DiscountMatchStatus.applicable)
              .toList();
          final budgetNotMet = discounts
              .where((d) => d.status == DiscountMatchStatus.budgetNotMet)
              .toList();
          final notMember = discounts
              .where((d) => d.status == DiscountMatchStatus.notMember)
              .toList();
          final missingPayment = discounts
              .where((d) => d.status == DiscountMatchStatus.missingPayment)
              .toList();
          final individualProduct = discounts
              .where((d) => d.status == DiscountMatchStatus.individualProduct)
              .toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Text(
                    '${_getRelativeDateText(date, l10n)} (${dateFormatter.format(date)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Items
                buildCategoryFlexbox('', applicable, date),
                if (_showAllShopDiscounts) ...[
                  buildCategoryFlexbox(
                    l10n.catBudgetNotMet,
                    budgetNotMet,
                    date,
                  ),
                  buildCategoryFlexbox(l10n.catNotMember, notMember, date),
                  buildCategoryFlexbox(
                    l10n.catMissingPayment,
                    missingPayment,
                    date,
                  ),
                ],
                if (_showIndividualProducts)
                  buildCategoryFlexbox(
                    l10n.catIndividualProduct,
                    individualProduct,
                    date,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
