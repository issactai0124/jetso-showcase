import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jetso_showcase/models/discount.dart';
import 'package:jetso_showcase/providers/discount_engine.dart';
import 'package:jetso_showcase/providers/data_provider.dart';
import 'package:jetso_showcase/providers/persistence_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Discount engine filters correctly', () async {
    SharedPreferences.setMockInitialValues({
      SettingsNotifier.keySelectedPayments: ['enjoy_card'],
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        discountsProvider.overrideWithValue([
          Discount(
            id: 'd1',
            shopIds: ['wellcome'],
            requiredPaymentIds: ['enjoy_card'],
            titleZh: 'Test Discount',
            titleEn: 'Test',
            type: 'percentage_discount',
            conditions: DiscountCondition(minSpend: 100, excludePaymentIds: []),
            schedule: DiscountSchedule(
              applicableDaysOfMonth: [],
              applicableDaysOfWeek: [],
            ),
            rewards: DiscountReward(rate: 0.1),
          ),
        ]),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Initial state: empty selection
    var discounts = container.read(applicableDiscountsProvider);
    expect(discounts.isEmpty, true);

    // Selection 1: wrong amount, wrong payment
    container
        .read(userInputProvider.notifier)
        .updateState(
          UserInput(shopId: 'wellcome', amount: 50.0, date: DateTime.now()),
        );

    discounts = container.read(applicableDiscountsProvider);
    expect(discounts.isNotEmpty, true);
    expect(discounts.first.status, DiscountMatchStatus.budgetNotMet);

    // Selection 2: correct payment, correct amount
    container
        .read(userInputProvider.notifier)
        .updateState(
          UserInput(shopId: 'wellcome', amount: 150.0, date: DateTime.now()),
        );

    discounts = container.read(applicableDiscountsProvider);
    expect(discounts.isNotEmpty, true);
    expect(discounts.first.status, DiscountMatchStatus.applicable);
    expect(discounts.first.discount.id, 'd1');
  });
}
