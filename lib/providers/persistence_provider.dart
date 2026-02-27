import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/persistence_models.dart';

// --- Shared Preferences Instance Provider ---
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main() overrides');
});

// --- Settings Providers ---
class SettingsNotifier extends Notifier<Map<String, dynamic>> {
  static const String keyDefaultAlarmTime = 'defaultAlarmTime';
  static const String keySelectedPayments = 'selectedPayments';
  static const String keyDefaultBudget = 'defaultBudget';
  static const String keyThemeMode = 'themeMode';
  static const String keyLanguage = 'language';
  static const String keyShowAllShopDiscounts = 'showAllShopDiscounts';
  static const String keyShowIndividualProducts = 'showIndividualProducts';

  @override
  Map<String, dynamic> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      keyDefaultAlarmTime: prefs.getString(keyDefaultAlarmTime) ?? '12:00',
      keySelectedPayments: prefs.getStringList(keySelectedPayments) ?? [],
      keyDefaultBudget: prefs.getDouble(keyDefaultBudget) ?? 9999.0,
      keyThemeMode: prefs.getString(keyThemeMode) ?? 'dark',
      keyLanguage: prefs.getString(keyLanguage) ?? 'zh',
      keyShowAllShopDiscounts: prefs.getBool(keyShowAllShopDiscounts) ?? true,
      keyShowIndividualProducts:
          prefs.getBool(keyShowIndividualProducts) ?? true,
    };
  }

  void updateDefaultAlarmTime(String time) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(keyDefaultAlarmTime, time);
    state = {...state, keyDefaultAlarmTime: time};
  }

  void updateSelectedPayments(List<String> payments) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setStringList(keySelectedPayments, payments);
    state = {...state, keySelectedPayments: payments};
  }

  void updateDefaultBudget(double budget) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setDouble(keyDefaultBudget, budget);
    state = {...state, keyDefaultBudget: budget};
  }

  void updateThemeMode(String mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(keyThemeMode, mode);
    state = {...state, keyThemeMode: mode};
  }

  void updateLanguage(String lang) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(keyLanguage, lang);
    state = {...state, keyLanguage: lang};
  }

  void updateShowAllShopDiscounts(bool show) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(keyShowAllShopDiscounts, show);
    state = {...state, keyShowAllShopDiscounts: show};
  }

  void updateShowIndividualProducts(bool show) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(keyShowIndividualProducts, show);
    state = {...state, keyShowIndividualProducts: show};
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, dynamic>>(() {
      return SettingsNotifier();
    });

// --- Search History Providers ---
class SearchHistoryNotifier extends Notifier<Map<String, List<String>>> {
  static const String keyRecentShops = 'recentShops';

  @override
  Map<String, List<String>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {keyRecentShops: prefs.getStringList(keyRecentShops) ?? []};
  }

  void addRecentShop(String shopId) {
    final prefs = ref.read(sharedPreferencesProvider);
    List<String> recents = List.from(state[keyRecentShops] ?? []);
    recents.remove(shopId); // Remove if exists
    recents.insert(0, shopId); // Add to top
    if (recents.length > 5) recents.removeLast(); // Keep max 5

    prefs.setStringList(keyRecentShops, recents);
    state = {...state, keyRecentShops: recents};
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, Map<String, List<String>>>(() {
      return SearchHistoryNotifier();
    });

// --- Presets Provider ---
class PresetsNotifier extends Notifier<List<PresetSearch>> {
  static const String keyPresets = 'presetSearches';

  @override
  List<PresetSearch> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final String? data = prefs.getString(keyPresets);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => PresetSearch.fromJson(e)).toList();
  }

  void savePreset(PresetSearch preset) {
    final prefs = ref.read(sharedPreferencesProvider);
    List<PresetSearch> current = List.from(state);
    if (current.length >= 5) current.removeLast(); // Keep max 5
    current.insert(0, preset);

    prefs.setString(
      keyPresets,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    state = current;
  }

  void deletePreset(String id) {
    final prefs = ref.read(sharedPreferencesProvider);
    List<PresetSearch> current = state.where((e) => e.id != id).toList();

    prefs.setString(
      keyPresets,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    state = current;
  }
}

final presetsProvider = NotifierProvider<PresetsNotifier, List<PresetSearch>>(
  () {
    return PresetsNotifier();
  },
);

// --- Reminders Provider ---
class RemindersNotifier extends Notifier<List<AlarmReminder>> {
  static const String keyReminders = 'alarmReminders';

  @override
  List<AlarmReminder> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final String? data = prefs.getString(keyReminders);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => AlarmReminder.fromJson(e)).toList();
  }

  void saveReminder(AlarmReminder reminder) {
    final prefs = ref.read(sharedPreferencesProvider);
    List<AlarmReminder> current = List.from(state);
    int index = current.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      current[index] = reminder; // Update existing
    } else {
      current.add(reminder); // Add new
    }

    prefs.setString(
      keyReminders,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    state = current;
  }

  void deleteReminder(String id) {
    final prefs = ref.read(sharedPreferencesProvider);
    List<AlarmReminder> current = state.where((e) => e.id != id).toList();

    prefs.setString(
      keyReminders,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    state = current;
  }
}

final remindersProvider =
    NotifierProvider<RemindersNotifier, List<AlarmReminder>>(() {
      return RemindersNotifier();
    });
