import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/persistence_provider.dart';

class AppL10n {
  final String langCode;
  AppL10n(this.langCode);

  bool get isEn => langCode == 'en';

  // Navigation
  String get navSearch => isEn ? 'Search' : '搜尋';
  String get navPreset => isEn ? 'Preset' : '預設';
  String get navReminder => isEn ? 'Reminder' : '提醒';
  String get navSettings => isEn ? 'Settings' : '設定';

  // Home Screen
  String get homeTitle => isEn ? 'HK Jetso Searcher' : '香港商舖優惠搜尋器 Jetso HK';
  String get homeSelectShop => isEn ? 'Select Shop' : '選擇商舖';
  String get homeBudget => isEn ? 'Budget / Min Spend' : '預算 / 最低消費額';
  String get homeBudgetHint => isEn ? 'Leave empty for unlimited' : '留空為無限制';
  String get homeSavedToPreset => isEn ? 'Saved to Presets!' : '已儲存至預設搜尋！';
  String get homeSearch => isEn ? 'Search Deals' : '搜尋優惠';

  // Search Results
  String get searchResults => isEn ? 'Search Results' : '搜尋結果';
  String get showAllDiscounts => isEn ? 'Show All Shop Deals' : '顯示商舖全部優惠';
  String get showIndividualProducts =>
      isEn ? 'Show Individual Products' : '顯示個別產品的優惠';
  String get saveToPreset => isEn ? 'Save to Presets' : '儲存到預設搜尋';

  String get shopUnknown => isEn ? 'Unknown Shop' : '未知商舖';
  String get budgetLabel => isEn ? 'Budget: ' : '預算: ';
  String get budgetUnlimited => isEn ? 'Unlimited' : '無限制';

  // Relative dates
  String get dateToday => isEn ? 'Today' : '今天';
  String get dateTomorrow => isEn ? 'Tomorrow' : '明天';
  String dateDaysLater(int days) => isEn ? 'In $days days' : '$days天後';

  // Categories
  String get catApplicable => isEn ? 'Applicable Deals' : '符合條件優惠';
  String get catBudgetNotMet =>
      isEn ? 'Budget Requirement Not Met' : '預算未達簽帳要求';
  String get catNotMember => isEn ? 'Membership Required' : '未加入會員';
  String get catMissingPayment => isEn ? 'Missing Payment Method' : '未持有相關支付方法';
  String get catIndividualProduct =>
      isEn ? 'Individual Product Deals' : '個別產品優惠';

  // Search Results Specific
  String get searchSelectShopFirst =>
      isEn ? 'Please go back and select a shop first' : '請先於上一頁選擇商舖';
  String get searchNoResults =>
      isEn ? 'No deals match your criteria' : '目前沒有符合條件的優惠';
  String get maxPresetsReached =>
      isEn ? 'Saved to presets (Max 5)' : '已儲存至預設搜尋 (最多5個)';
  String get minSpendTitle =>
      isEn ? 'Min Spend Requirement: HK\$' : '簽帳要求: HK\$';

  // Discount item
  String get minSpendPrefix => isEn ? 'Min Spend: HK\$' : '需要最低消費: HK\$';
  String get rewardRatePrefix => isEn ? 'Discount: ' : '優惠: ';
  String get rewardAmountPrefix => isEn ? 'Discount Amount: HK\$' : '優惠額: HK\$';
  String get addToReminders => isEn ? 'Add to Reminders' : '加入提醒';
  String validUntil(String date) => isEn ? 'Valid until $date' : '有效至 $date';
  String get validToday => isEn ? 'Valid until today' : '有效至今天';
  String get validTomorrow => isEn ? 'Valid until tomorrow' : '有效至明天';

  // Preset Screen
  String get presetTitle => isEn ? 'Saved Presets' : '預設搜尋';
  String get presetEmpty => isEn ? 'No saved presets' : '尚無預設搜尋';
  String get tapToSearch => isEn ? 'Tap to search' : '點擊以搜尋';
  String get deletePreset => isEn ? 'Delete Preset' : '刪除預設';
  String get confirmDeletePreset =>
      isEn ? 'Are you sure you want to delete this preset?' : '確定要刪除這個預設搜尋嗎？';
  String get cancel => isEn ? 'Cancel' : '取消';
  String get confirm => isEn ? 'Confirm' : '確定';

  // Reminder Screen
  String get reminderTitle => isEn ? 'Reminders' : '優惠提醒';
  String get reminderEmpty => isEn ? 'No saved reminders' : '尚無優惠提醒';
  String get editReminder => isEn ? 'Edit Reminder' : '編輯提醒時間';
  String get changeDate => isEn ? 'Change Date' : '更改日期';
  String get changeTime => isEn ? 'Change Time' : '更改時間';
  String get deleteReminder => isEn ? 'Delete Reminder' : '刪除提醒';
  String get confirmDeleteReminder =>
      isEn ? 'Are you sure you want to delete this reminder?' : '確定要刪除這個優惠提醒嗎？';
  String get update => isEn ? 'Update' : '更新';
  String get reminderTimePrefix => isEn ? 'Reminder Time:' : '提醒時間:';

  // Calendar Screen
  String get calendarTitle => isEn ? 'Deal Calendar' : '優惠日曆';
  String get typePercentage => isEn ? 'Percentage Discount' : '百分比優惠';
  String get typePoints => isEn ? 'Points Redemption' : '積分換領';
  String get typeFixed => isEn ? 'Fixed Discount' : '固定優惠';

  // Settings Screen
  String get settingsTheme => isEn ? 'Theme' : '主題';
  String get settingsThemeDark => isEn ? 'Dark Theme' : '深色模式 (Dark Theme)';
  String get settingsThemeLight => isEn ? 'Light Theme' : '淺色模式 (Light Theme)';
  String get settingsLanguage => isEn ? 'Language' : '語言 (Language)';

  String get settingsDefaultBudget => isEn ? 'Default Budget' : '預設簽帳預算';
  String get settingsDefaultAlarm => isEn ? 'Default Alarm Time' : '預設提醒時間';
  String get settingsSelectPayments =>
      isEn ? 'Select your payment methods and memberships:' : '請選擇您擁有的付款方式與會員：';

  String get editDefaultBudget => isEn ? 'Edit Default Budget' : '修改預設預算';

  String get eWallets => isEn ? 'E-Wallets' : '電子支付';
  String get creditCards => isEn ? 'Credit Cards' : '信用卡';
  String get memberships => isEn ? 'Memberships' : '會員';
  String get identities => isEn ? 'Identity / Eligibility' : '身份';
  String get others => isEn ? 'Others' : '其他';

  // Dialogs
  String setAlarmFor(String title) =>
      isEn ? 'Set alarm for\n$title' : '設定提醒\n$title';
  String get savedToReminders => isEn ? 'Saved to Reminders!' : '已加入提醒！';

  // Shop Categories
  String get catSupermarket => isEn ? 'Supermarket' : '大型超市';
  String get catConvenience => isEn ? 'Convenience Store' : '便利店';
  String get catHealth => isEn ? 'Health & Beauty' : '健康美容';
  String get catBakery => isEn ? 'Bakery' : '餅店';
  String get catFood => isEn ? 'Food' : '食品';
  String get catBeverage => isEn ? 'Beverage' : '飲品';
  // String get catSeafood => isEn ? 'Dried Seafood' : '海味乾貨';
  String get catOther => isEn ? 'Other' : '其他';

  // Locale translation helpers
  String get dateShortFormat => isEn ? 'MMM dd' : 'MM月dd日';
  String get dateLongFormat => isEn ? 'MMM dd, yyyy HH:mm' : 'yyyy-MM-dd HH:mm';

  String trShopName(dynamic nameZh, dynamic nameEn) =>
      isEn && nameEn != null && nameEn.isNotEmpty ? nameEn : nameZh;
  String trDiscountTitle(dynamic titleZh, dynamic titleEn) =>
      isEn && titleEn != null && titleEn.isNotEmpty ? titleEn : titleZh;
  String trDescription(dynamic descZh, dynamic descEn) =>
      isEn && descEn != null && descEn.isNotEmpty ? descEn : (descZh ?? '');
}

final l10nProvider = Provider<AppL10n>((ref) {
  final settings = ref.watch(settingsProvider);
  final langCode = settings[SettingsNotifier.keyLanguage] as String? ?? 'zh';
  return AppL10n(langCode);
});
