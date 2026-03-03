import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import '../providers/discount_engine.dart';
import '../providers/persistence_provider.dart';
import '../models/shop.dart';
import '../models/category_config.dart';
import 'search_results_screen.dart';
import '../l10n/app_l10n.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
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
      appBar: AppBar(title: Text(l10n.searchTitle)),
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
                l10n.searchSearch,
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
          Row(
            children: [
              Text(
                l10n.searchBudget,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
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
                    hintText: l10n.searchBudgetHint,
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
    final categoryConfig = ref.watch(categoryConfigProvider);
    if (categoryConfig == null) return const SizedBox.shrink();

    // 1. Group by Main Category using the order from config
    final Map<String, List<Shop>> groupedByMain = {};
    for (var cat in categoryConfig.categories) {
      groupedByMain[cat.id] = shops.where((s) => s.category == cat.id).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryConfig.categories.map((catGroup) {
        final mainCatShops = groupedByMain[catGroup.id]!;
        if (mainCatShops.isEmpty) return const SizedBox.shrink();

        // 2. Further group by Sub Category inside each main category
        final Map<String, List<Shop>> groupedBySub = {};
        for (var s in mainCatShops) {
          final sub = s.subCategory ?? '';
          groupedBySub.putIfAbsent(sub, () => []).add(s);
        }

        // 3. Sort existing subcategories based on config order
        final List<String> sortedSubs = [];
        for (var subInfo in catGroup.subcategories) {
          if (groupedBySub.containsKey(subInfo.id)) {
            sortedSubs.add(subInfo.id);
          }
        }
        // Add any subcategories that are in shops but NOT in config at the end
        for (var existingSub in groupedBySub.keys) {
          if (!sortedSubs.contains(existingSub)) {
            sortedSubs.add(existingSub);
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Category Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _parseHexColor(catGroup.color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.isEn ? catGroup.nameEn : catGroup.nameZh,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _parseHexColor(catGroup.color),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Sub Category Groups
              ...sortedSubs.map((subCat) {
                final subShops = groupedBySub[subCat]!;
                // Sort shops within sub-category by ID or name
                subShops.sort((a, b) => a.nameZh.compareTo(b.nameZh));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subCat.isNotEmpty) ...[
                        Text(
                          _getSubCategoryLabel(catGroup, subCat, l10n),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: subShops
                            .map(
                              (shop) => _buildShopPill(shop, userInput, l10n),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _parseHexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _getSubCategoryLabel(
    CategoryGroup catGroup,
    String subId,
    AppL10n l10n,
  ) {
    if (subId.isEmpty) return '';
    final subInfo = catGroup.subcategories.firstWhere(
      (s) => s.id == subId,
      orElse: () => SubCategoryInfo(id: subId, nameZh: subId, nameEn: subId),
    );
    return l10n.isEn ? subInfo.nameEn : subInfo.nameZh;
  }

  Widget _buildShopPill(Shop shop, UserInput userInput, AppL10n l10n) {
    final isSelected = userInput.shopId == shop.id;
    final categoryConfig = ref.watch(categoryConfigProvider);
    final catGroup = categoryConfig?.categories.firstWhere(
      (c) => c.id == shop.category,
      orElse: () => CategoryGroup(
        id: '其他',
        nameZh: '其他',
        nameEn: 'Other',
        color: '#455A64',
        subcategories: [],
      ),
    );
    final catColor = _parseHexColor(catGroup?.color ?? '#455A64');
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
