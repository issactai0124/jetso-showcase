import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/discount_engine.dart';
import '../providers/data_provider.dart';
import '../providers/persistence_provider.dart';
import '../models/shop.dart';
import '../models/payment_method.dart';
import '../l10n/app_l10n.dart';
import '../widgets/discount_tile.dart';
import '../models/persistence_models.dart';
import '../models/discount.dart';

class RecentScreen extends ConsumerStatefulWidget {
  const RecentScreen({super.key});

  @override
  ConsumerState<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends ConsumerState<RecentScreen> {
  void _showAlarmDialog(
    BuildContext context,
    Discount discount,
    Shop shop,
    DateTime date,
  ) async {
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
        shopId: shop.id,
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

  @override
  Widget build(BuildContext context) {
    final groupedDiscounts = ref.watch(globalGroupedDiscountsProvider);
    final l10n = ref.watch(l10nProvider);
    final settings = ref.watch(settingsProvider);
    final allShops = ref.watch(shopsProvider);
    final paymentMethods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recentTitle),
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
            if (groupedDiscounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.searchNoResults),
              )
            else
              _buildRecentList(
                context,
                groupedDiscounts,
                paymentMethods,
                allShops,
                l10n,
                settings,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList(
    BuildContext context,
    Map<DateTime, List<CategorizedDiscount>> groupedDiscounts,
    List<PaymentMethod> paymentMethods,
    List<Shop> allShops,
    AppL10n l10n,
    Map<String, dynamic> settings,
  ) {
    final sortedDates = groupedDiscounts.keys.toList()..sort();
    final dateFormatter = DateFormat(l10n.dateShortFormat);

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

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
        userBudget:
            settings[SettingsNotifier.keyDefaultBudget] as double? ?? 9999.0,
        showShopName: true,
        onAddAlarm: () =>
            _showAlarmDialog(context, catDiscount.discount, activeShop, date),
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

      final isNegative =
          title == l10n.catNotMember || title == l10n.catMissingPayment;
      final borderColor = isNegative
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);

      final headerBgColor = isNegative
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);

      final headerTextColor = isNegative
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
        ...sortedDates.expand<Widget>((date) {
          final isToday =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final isTomorrow =
              date.year == tomorrow.year &&
              date.month == tomorrow.month &&
              date.day == tomorrow.day;

          // Exclude anything that isn't Today or Tomorrow
          if (!isToday && !isTomorrow) {
            return [];
          }

          final discounts = groupedDiscounts[date]!;

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
            final notMember = items
                .where((d) => d.status == DiscountMatchStatus.notMember)
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
                    buildCategoryFlexbox(l10n.catNotMember, notMember, date),
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
              '${l10n.dateTomorrow} (${dateFormatter.format(date)})',
            ),
          ];
        }),
      ],
    );
  }
}
