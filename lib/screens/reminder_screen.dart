import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/persistence_provider.dart';
import '../providers/data_provider.dart';
import '../models/persistence_models.dart';
import 'package:intl/intl.dart';
import '../l10n/app_l10n.dart';

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final discounts = ref.watch(discountsProvider);
    final shops = ref.watch(shopsProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminderTitle)),
      body: reminders.isEmpty
          ? Center(child: Text(l10n.reminderEmpty))
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final discount = discounts.firstWhere(
                  (d) => d.id == reminder.discountId,
                  orElse: () => discounts.first,
                );
                final shop = shops.firstWhere(
                  (s) => s.id == reminder.shopId,
                  orElse: () => shops.first,
                );

                final timeFormatter = DateFormat(l10n.dateLongFormat);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.access_alarm,
                      color: Colors.amber,
                    ),
                    title: Text(
                      l10n.trDiscountTitle(discount.titleZh, discount.titleEn),
                    ),
                    subtitle: Text(
                      '${l10n.trShopName(shop.nameZh, shop.nameEn)} • ${l10n.reminderTimePrefix} ${timeFormatter.format(reminder.triggerTime.toLocal())}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.deleteReminder),
                            content: Text(l10n.confirmDeleteReminder),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(remindersProvider.notifier)
                                      .deleteReminder(reminder.id);
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
                    onTap: () async {
                      // Modify Reminder Time
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: reminder.triggerTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (selectedDate != null && context.mounted) {
                        final selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            reminder.triggerTime,
                          ),
                        );
                        if (selectedTime != null) {
                          final newTriggerTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final updated = AlarmReminder(
                            id: reminder.id,
                            discountId: reminder.discountId,
                            shopId: reminder.shopId,
                            triggerTime: newTriggerTime,
                          );
                          ref
                              .read(remindersProvider.notifier)
                              .saveReminder(updated);
                        }
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
