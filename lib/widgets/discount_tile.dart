import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/discount.dart';
import '../models/payment_method.dart';
import '../models/shop.dart';
import '../l10n/app_l10n.dart';

class DiscountTile extends StatelessWidget {
  final Discount discount;
  final Shop activeShop;
  final List<PaymentMethod> paymentMethods;
  final AppL10n l10n;
  final double? userBudget;
  final VoidCallback onAddAlarm;
  final bool showShopName;

  const DiscountTile({
    super.key,
    required this.discount,
    required this.activeShop,
    required this.paymentMethods,
    required this.l10n,
    this.userBudget,
    required this.onAddAlarm,
    this.showShopName = false,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    // For deep links (non-http), or for specific platforms like RewardBuy (http),
    // use externalApplication mode to force "open in new window" (browser/app).
    LaunchMode mode = LaunchMode.platformDefault;
    if (!urlString.startsWith('http') || urlString.contains('rewardbuy.shop')) {
      mode = LaunchMode.externalApplication;
    }

    try {
      if (!await launchUrl(url, mode: mode)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching $urlString: $e');
    }
  }

  Color _getPaymentTypeColor(String type) {
    switch (type) {
      case 'e_wallet':
        return Colors.teal;
      case 'credit_card':
        return Colors.orange.shade800;
      case 'membership':
        return Colors.blue.shade600;
      case 'tag':
        return Colors.purple.shade500;
      case 'identity':
      case 'octopus':
        return Colors.pink.shade600;
      default:
        return Colors.blueGrey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat(l10n.dateShortFormat);
    final shopNameTitle = l10n.trShopName(activeShop.nameZh, activeShop.nameEn);
    final discountTitle = l10n.trDiscountTitle(
      discount.titleZh,
      discount.titleEn,
    );
    final displayTitle = showShopName
        ? '【$shopNameTitle】 $discountTitle'
        : discountTitle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                if (pm.appUrl != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _launchUrl(pm.appUrl!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.open_in_new,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            pm.appUrl!.startsWith('http')
                                                ? l10n.openWebsite
                                                : l10n.openApp,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
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
                              color: isExpiringSoon
                                  ? Colors.redAccent
                                  : Colors.grey,
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
                          color:
                              (userBudget != null &&
                                  discount.conditions.minSpend > userBudget!)
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
              ),
              IconButton(
                icon: Icon(
                  Icons.alarm_add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: l10n.addToReminders,
                onPressed: onAddAlarm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
