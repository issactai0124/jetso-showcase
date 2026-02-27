import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discount.dart';
import 'data_provider.dart';
import 'persistence_provider.dart';

class UserInput {
  final String shopId;
  final double amount;
  final DateTime date;

  UserInput({required this.shopId, required this.amount, required this.date});

  UserInput copyWith({String? shopId, double? amount, DateTime? date}) {
    return UserInput(
      shopId: shopId ?? this.shopId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}

class UserInputNotifier extends Notifier<UserInput> {
  @override
  UserInput build() {
    final settings = ref.watch(settingsProvider);
    final defaultBudget = settings[SettingsNotifier.keyDefaultBudget] as double;
    return UserInput(shopId: '', amount: defaultBudget, date: DateTime.now());
  }

  void updateState(UserInput newState) {
    state = newState;
  }
}

final userInputProvider = NotifierProvider<UserInputNotifier, UserInput>(() {
  return UserInputNotifier();
});

enum DiscountMatchStatus {
  applicable,
  budgetNotMet,
  notMember,
  missingPayment,
  individualProduct,
}

class CategorizedDiscount {
  final Discount discount;
  final DiscountMatchStatus status;

  CategorizedDiscount({required this.discount, required this.status});
}

final applicableDiscountsProvider = Provider<List<CategorizedDiscount>>((ref) {
  final discounts = ref.watch(discountsProvider);
  final paymentMethods = ref.watch(paymentMethodsProvider);
  final userInput = ref.watch(userInputProvider);
  final settings = ref.watch(settingsProvider);
  final selectedPayments = List<String>.from(
    settings[SettingsNotifier.keySelectedPayments] ?? [],
  );

  if (userInput.shopId.isEmpty) return [];

  final List<CategorizedDiscount> result = [];

  for (var discount in discounts) {
    // 1. Check Shop
    if (!discount.shopIds.contains(userInput.shopId)) continue;

    // 2. Check Expiration & Generic bounds
    if (discount.schedule.endDate != null &&
        DateTime.now().isAfter(
          discount.schedule.endDate!.add(const Duration(days: 1)),
        )) {
      continue; // Completely expired
    }

    // 3. Check Exclude Payments
    if (discount.conditions.excludePaymentIds.isNotEmpty) {
      bool hasExcluded = discount.conditions.excludePaymentIds.any(
        (id) => selectedPayments.contains(id),
      );
      if (hasExcluded) continue;
    }

    // 4. Individual Product Check
    if (discount.isProduct) {
      result.add(
        CategorizedDiscount(
          discount: discount,
          status: DiscountMatchStatus.individualProduct,
        ),
      );
      continue;
    }

    // Track matching state logic
    DiscountMatchStatus currentStatus = DiscountMatchStatus.applicable;

    // 5. Check Required Payments
    if (discount.requiredPaymentIds.isNotEmpty) {
      bool hasRequiredPayment = discount.requiredPaymentIds.any(
        (id) => selectedPayments.contains(id),
      );
      if (!hasRequiredPayment) {
        // Determine if missing payment is a membership
        bool isMembership = false;
        for (var reqId in discount.requiredPaymentIds) {
          try {
            final pm = paymentMethods.firstWhere((p) => p.id == reqId);
            if (pm.type == 'membership' || pm.type == 'identity') {
              isMembership = true;
              break;
            }
          } catch (_) {}
        }
        currentStatus = isMembership
            ? DiscountMatchStatus.notMember
            : DiscountMatchStatus.missingPayment;
      }
    }

    // 6. Check Target Budget Minimum Spend
    if (currentStatus == DiscountMatchStatus.applicable) {
      final effectiveAmount = userInput.amount == 9999.0
          ? 999999.0
          : userInput.amount;
      if (effectiveAmount < discount.conditions.minSpend) {
        currentStatus = DiscountMatchStatus.budgetNotMet;
      }
    }

    // 7. Decide inclusion
    result.add(CategorizedDiscount(discount: discount, status: currentStatus));
  }

  return result;
});

class DiscountWithDate {
  final CategorizedDiscount categorizedDiscount;
  final DateTime date;

  DiscountWithDate({required this.categorizedDiscount, required this.date});
}

final groupedDiscountsProvider =
    Provider<Map<DateTime, List<CategorizedDiscount>>>((ref) {
      final applicableDiscounts = ref.watch(applicableDiscountsProvider);
      if (applicableDiscounts.isEmpty) return {};

      final Map<DateTime, List<CategorizedDiscount>> grouped = {};
      final today = DateTime.now();
      final maxDays = 30; // Look ahead 30 days

      for (var catDiscount in applicableDiscounts) {
        final discount = catDiscount.discount;
        if (discount.schedule.applicableDaysOfMonth.isEmpty &&
            discount.schedule.applicableDaysOfWeek.isEmpty &&
            discount.schedule.startDate == null &&
            discount.schedule.endDate == null) {
          // Always applicable, put in "Today"
          final dateKey = DateTime(today.year, today.month, today.day);
          grouped.putIfAbsent(dateKey, () => []).add(catDiscount);
          continue;
        }

        // Check each of the next 30 days
        for (int i = 0; i < maxDays; i++) {
          final checkDate = today.add(Duration(days: i));
          final dateKey = DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
          );

          bool applies = true;
          if (discount.schedule.startDate != null &&
              checkDate.isBefore(discount.schedule.startDate!)) {
            applies = false;
          }
          if (discount.schedule.endDate != null &&
              checkDate.isAfter(
                discount.schedule.endDate!.add(const Duration(days: 1)),
              )) {
            applies = false;
          }

          if (applies && discount.schedule.applicableDaysOfMonth.isNotEmpty) {
            if (!discount.schedule.applicableDaysOfMonth.contains(
              checkDate.day,
            )) {
              applies = false;
            }
          }

          if (applies && discount.schedule.applicableDaysOfWeek.isNotEmpty) {
            if (!discount.schedule.applicableDaysOfWeek.contains(
              checkDate.weekday,
            )) {
              applies = false;
            }
          }

          if (applies) {
            grouped.putIfAbsent(dateKey, () => []).add(catDiscount);
          }
        }
      }

      // Post-processing: Deduplicate discounts, keeping only the earliest occurrence
      final Map<DateTime, List<CategorizedDiscount>> refinedGrouped = {};
      final Set<String> seenDiscountIds = {};

      // Sort keys chronologically
      final sortedDates = grouped.keys.toList()..sort();

      for (final date in sortedDates) {
        for (final catDiscount in grouped[date]!) {
          if (!seenDiscountIds.contains(catDiscount.discount.id)) {
            seenDiscountIds.add(catDiscount.discount.id);
            refinedGrouped.putIfAbsent(date, () => []).add(catDiscount);
          }
        }
      }

      return refinedGrouped;
    });
