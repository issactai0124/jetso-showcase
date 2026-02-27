import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import '../providers/discount_engine.dart';
import '../providers/persistence_provider.dart';
import '../models/shop.dart';
import 'calendar_screen.dart';
import 'search_results_screen.dart';
import '../l10n/app_l10n.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final input = ref.read(userInputProvider);
      if (input.amount > 0 && input.amount < 9999.0) {
        _amountController.text = input.amount.toStringAsFixed(0);
      } else if (input.amount >= 9999.0) {
        _amountController.text = '';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _adjustAmount(bool increase) {
    final current = ref.read(userInputProvider).amount;
    final steps = [10.0, 50.0, 100.0, 200.0, 500.0, 1000.0, 9999.0];
    double nextAmount = current;

    if (increase) {
      nextAmount = steps.firstWhere((s) => s > current, orElse: () => 9999.0);
    } else {
      nextAmount = steps.lastWhere((s) => s < current, orElse: () => 10.0);
    }
    _setAmount(nextAmount);
  }

  void _setAmount(double amount) {
    ref
        .read(userInputProvider.notifier)
        .updateState(ref.read(userInputProvider).copyWith(amount: amount));
    _amountController.text = amount >= 9999.0 ? '' : amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final userInput = ref.watch(userInputProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: userInput.shopId.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchResultsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: Text(
                l10n.homeSearch,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }

  Widget _buildContent() {
    final allShops = ref.watch(shopsProvider);
    final userInput = ref.watch(userInputProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final l10n = ref.watch(l10nProvider);

    final recentShopIds =
        searchHistory[SearchHistoryNotifier.keyRecentShops] ?? [];

    final recentShops = recentShopIds
        .map(
          (id) => allShops.firstWhere(
            (s) => s.id == id,
            orElse: () => allShops.first,
          ),
        )
        .where((s) => recentShopIds.contains(s.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 80.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shop Selection
          Text(
            l10n.homeSelectShop,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (recentShops.isNotEmpty) ...[
            Text(
              l10n.isEn ? 'Recent' : '最近搜尋',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Wrap(
              spacing: 8.0,
              children: recentShops
                  .map((shop) => _buildShopPill(shop, userInput, l10n))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],

          if (allShops.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCategorizedShops(allShops, userInput, l10n),
          ],

          const SizedBox(height: 24),

          // 2. Amount Input
          Text(
            l10n.homeBudget,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n.homeBudgetHint,
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      ref
                          .read(userInputProvider.notifier)
                          .updateState(userInput.copyWith(amount: 9999.0));
                    } else {
                      final amount = double.tryParse(value) ?? 0.0;
                      if (amount > 0) {
                        ref
                            .read(userInputProvider.notifier)
                            .updateState(userInput.copyWith(amount: amount));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                label: const Text('<<'),
                onPressed: () => _adjustAmount(false),
              ),
              ActionChip(
                label: const Text('\$50'),
                onPressed: () => _setAmount(50),
              ),
              ActionChip(
                label: const Text('\$100'),
                onPressed: () => _setAmount(100),
              ),
              ActionChip(
                label: const Text('\$200'),
                onPressed: () => _setAmount(200),
              ),
              ActionChip(
                label: const Text('\$500'),
                onPressed: () => _setAmount(500),
              ),
              ActionChip(
                label: const Text('\$1000'),
                onPressed: () => _setAmount(1000),
              ),
              ActionChip(
                label: const Text('>>'),
                onPressed: () => _adjustAmount(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedShops(
    List<Shop> shops,
    UserInput userInput,
    AppL10n l10n,
  ) {
    const categoryOrder = ['大型超市', '便利店', '健康美容', '餅店', '食品', '飲品', '其他'];
    final Map<String, List<Shop>> grouped = {};
    for (var cat in categoryOrder) {
      grouped[cat] = shops.where((s) => s.category == cat).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryOrder.map((cat) {
        final catShops = grouped[cat]!;
        if (catShops.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (cat) {
                  '大型超市' => l10n.catSupermarket,
                  '便利店' => l10n.catConvenience,
                  '健康美容' => l10n.catHealth,
                  '餅店' => l10n.catBakery,
                  '食品' => l10n.catFood,
                  '飲品' => l10n.catBeverage,
                  // '海味乾貨' => l10n.catSeafood,
                  _ => l10n.catOther,
                },
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: catShops
                    .map((shop) => _buildShopPill(shop, userInput, l10n))
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category, BuildContext context) {
    switch (category) {
      case '大型超市':
        return Colors.blue.shade700;
      case '便利店':
        return Colors.green.shade700;
      case '餅店':
        return Colors.orange.shade700;
      case '食品':
        return Colors.pink.shade700;
      case '飲品':
        return Colors.purple.shade700;
      case '海味乾貨':
        return Colors.brown.shade700;
      case '健康美容':
        return Colors.teal.shade500;
      case '其他':
      default:
        return Colors.grey.shade800;
    }
  }

  Widget _buildShopPill(Shop shop, UserInput userInput, AppL10n l10n) {
    final isSelected = userInput.shopId == shop.id;
    final catColor = _getCategoryColor(shop.category, context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? catColor : catColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: catColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref
                .read(userInputProvider.notifier)
                .updateState(userInput.copyWith(shopId: shop.id));
            ref.read(searchHistoryProvider.notifier).addRecentShop(shop.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.trShopName(shop.nameZh, shop.nameEn),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (shop.descriptionZh != null ||
                    shop.descriptionEn != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: l10n.trDescription(
                      shop.descriptionZh,
                      shop.descriptionEn,
                    ),
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 3),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.black54),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
