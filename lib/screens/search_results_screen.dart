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
import '../widgets/discount_tile.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  void _savePreset(AppL10n l10n) {
    final input = ref.read(userInputProvider);
    if (input.shopId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.searchSelectShopFirst)));
      return;
    }

    final presets = ref.read(presetsProvider);
    final isSavedAsPreset = presets.any(
      (p) => p.shopId == input.shopId && p.amount == input.amount,
    );

    if (isSavedAsPreset) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.presetAlreadyExists)));
      return;
    }

    final preset = PresetSearch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopId: input.shopId,
      amount: input.amount,
      createdAt: DateTime.now(),
    );
    ref.read(presetsProvider.notifier).savePreset(preset);

    final allShops = ref.read(shopsProvider);
    final activeShop = allShops.firstWhere(
      (s) => s.id == input.shopId,
      orElse: () => Shop(id: '', nameZh: '', nameEn: '', category: ''),
    );
    final shopName = l10n.trShopName(activeShop.nameZh, activeShop.nameEn);
    final budgetText = input.amount >= 9999.0
        ? l10n.budgetUnlimited
        : 'HK\$${input.amount.toStringAsFixed(0)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.presetSavedSuccess(shopName, budgetText))),
    );
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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final buildContext = context;

    final selectedDate = await showDatePicker(
      context: buildContext,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (selectedDate == null) return;
    if (!buildContext.mounted) return;
    final selectedTime = await showTimePicker(
      context: buildContext,
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

      if (!mounted) return;
      final l10n = ref.read(l10nProvider);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.savedToReminders)),
      );
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
    final settings = ref.watch(settingsProvider);

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
                value:
                    settings[SettingsNotifier.keyShowAllShopDiscounts]
                        as bool? ??
                    true,
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateShowAllShopDiscounts(val ?? true);
                },
              ),
              Tooltip(
                message: l10n.showAllDiscounts,
                child: Icon(
                  Icons.attach_money,
                  color:
                      (settings[SettingsNotifier.keyShowAllShopDiscounts]
                              as bool? ??
                          true)
                      ? Colors.green
                      : Colors.grey,
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
                value:
                    settings[SettingsNotifier.keyShowIndividualProducts]
                        as bool? ??
                    true,
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateShowIndividualProducts(val ?? true);
                },
              ),
              Tooltip(
                message: l10n.showIndividualProducts,
                child: Icon(
                  Icons.shopping_cart,
                  color:
                      (settings[SettingsNotifier.keyShowIndividualProducts]
                              as bool? ??
                          true)
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
                settings,
                isSavedAsPreset,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
    Map<DateTime, List<CategorizedDiscount>> groupedDiscounts,
    UserInput userInput,
    List<PaymentMethod> paymentMethods,
    List<Shop> allShops,
    AppL10n l10n,
    Map<String, dynamic> settings,
    bool isSavedAsPreset,
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
      final activeShop = allShops.firstWhere(
        (s) => catDiscount.discount.shopIds.contains(s.id),
        orElse: () => Shop(
          id: '',
          nameZh: l10n.shopUnknown,
          nameEn: l10n.shopUnknown,
          category: '',
        ),
      );

      return DiscountTile(
        discount: catDiscount.discount,
        activeShop: activeShop,
        paymentMethods: paymentMethods,
        l10n: l10n,
        userBudget: userInput.amount,
        onAddAlarm: () => _showAlarmDialog(catDiscount.discount, date),
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

      final isDimmed = title == l10n.catMissingPayment;
      final borderColor = isDimmed
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);

      final headerBgColor = isDimmed
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);

      final headerTextColor = isDimmed
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: headerTextColor,
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
        ),

        // Date Groups
        ...sortedDates.expand<Widget>((date) {
          final discounts = groupedDiscounts[date]!;
          final now = DateTime.now();
          final isToday =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          Widget buildDateContainer(
            List<CategorizedDiscount> items,
            String headerLabel,
          ) {
            if (items.isEmpty) return const SizedBox.shrink();

            final applicable = items
                .where((d) => d.status == DiscountMatchStatus.applicable)
                .toList();
            final budgetNotMet = items
                .where((d) => d.status == DiscountMatchStatus.budgetNotMet)
                .toList();
            final missingPayment = items
                .where((d) => d.status == DiscountMatchStatus.missingPayment)
                .toList();
            final individualProduct = items
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
                      headerLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  buildCategoryFlexbox('', applicable, date),
                  if (settings[SettingsNotifier.keyShowAllShopDiscounts]
                          as bool? ??
                      true) ...[
                    buildCategoryFlexbox(
                      l10n.catBudgetNotMet,
                      budgetNotMet,
                      date,
                    ),
                    buildCategoryFlexbox(
                      l10n.catMissingPayment,
                      missingPayment,
                      date,
                    ),
                  ],
                  if (settings[SettingsNotifier.keyShowIndividualProducts]
                          as bool? ??
                      true)
                    buildCategoryFlexbox(
                      l10n.catIndividualProduct,
                      individualProduct,
                      date,
                    ),
                ],
              ),
            );
          }

          if (isToday) {
            final onlyToday = <CategorizedDiscount>[];
            final applicableToday = <CategorizedDiscount>[];

            for (var d in discounts) {
              final schedule = d.discount.schedule;
              bool isStrictlyToday = false;
              if (schedule.applicableDaysOfMonth.isNotEmpty ||
                  schedule.applicableDaysOfWeek.isNotEmpty) {
                isStrictlyToday = true;
              } else if (schedule.endDate != null &&
                  schedule.endDate!.year == now.year &&
                  schedule.endDate!.month == now.month &&
                  schedule.endDate!.day == now.day) {
                isStrictlyToday = true;
              }

              if (isStrictlyToday) {
                onlyToday.add(d);
              } else {
                applicableToday.add(d);
              }
            }

            return [
              if (onlyToday.isNotEmpty)
                buildDateContainer(
                  onlyToday,
                  '${l10n.dateOnlyToday} (${dateFormatter.format(date)})',
                ),
              if (applicableToday.isNotEmpty)
                buildDateContainer(
                  applicableToday,
                  '${l10n.dateApplicableToday} (${dateFormatter.format(date)})',
                ),
            ];
          }

          return [
            buildDateContainer(
              discounts,
              '${_getRelativeDateText(date, l10n)} (${dateFormatter.format(date)})',
            ),
          ];
        }),
      ],
    );
  }
}
