import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import 'search_screen.dart';
import 'preset_screen.dart';
import 'reminder_screen.dart';
import 'settings_screen.dart';
import 'recent_screen.dart';
import '../l10n/app_l10n.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final initDataAsync = ref.watch(dataInitializationProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      body: initDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加載資料時發生錯誤: $err')),
        data: (_) => IndexedStack(
          index: _currentIndex,
          children: [
            const RecentScreen(),
            Navigator(
              key: _homeNavigatorKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                );
              },
            ),
            PresetScreen(
              homeNavigatorKey: _homeNavigatorKey,
              onNavigateToTab: (index) {
                setState(() {
                  _currentIndex = index;
                });
                if (index == 1) {
                  _homeNavigatorKey.currentState?.popUntil(
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            const ReminderScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1 && _currentIndex == 1) {
            _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          }
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.view_list),
            label: l10n.recentTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: l10n.navSearch,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: l10n.navPreset,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: l10n.navReminder,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
