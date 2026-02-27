import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/data_provider.dart';
import '../models/discount.dart';
import '../l10n/app_l10n.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Discount> _getDiscountsForDay(
    DateTime day,
    List<Discount> allDiscounts,
  ) {
    return allDiscounts.where((discount) {
      // Check date range
      if (discount.schedule.startDate != null &&
          day.isBefore(discount.schedule.startDate!)) {
        return false;
      }
      if (discount.schedule.endDate != null &&
          day.isAfter(discount.schedule.endDate!)) {
        return false;
      }

      // Check day of month
      if (discount.schedule.applicableDaysOfMonth.isNotEmpty) {
        if (!discount.schedule.applicableDaysOfMonth.contains(day.day)) {
          return false;
        }
      }

      // Check day of week
      if (discount.schedule.applicableDaysOfWeek.isNotEmpty) {
        if (!discount.schedule.applicableDaysOfWeek.contains(day.weekday)) {
          return false;
        }
      }

      return discount.schedule.applicableDaysOfMonth.isNotEmpty ||
          discount.schedule.applicableDaysOfWeek.isNotEmpty ||
          (discount.schedule.startDate != null &&
              discount.schedule.endDate != null);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final discounts = ref.watch(discountsProvider);
    final l10n = ref.watch(l10nProvider);
    final selectedDayDiscounts = _getDiscountsForDay(
      _selectedDay ?? _focusedDay,
      discounts,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: Column(
        children: [
          TableCalendar<Discount>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _getDiscountsForDay(day, discounts),
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: selectedDayDiscounts.length,
              itemBuilder: (context, index) {
                final discount = selectedDayDiscounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(
                      l10n.trDiscountTitle(discount.titleZh, discount.titleEn),
                    ),
                    subtitle: Text(
                      discount.type == 'percentage_discount'
                          ? l10n.typePercentage
                          : discount.type == 'points_redemption'
                          ? l10n.typePoints
                          : l10n.typeFixed,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
