import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(filteredInventoryProvider);
    final categories = ref.watch(inventoryCategoriesProvider);
    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final lowStockOnly = ref.watch(inventoryLowStockFilterProvider);
    final searchQuery = ref.watch(inventorySearchProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.contentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine & Consumables Inventory',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Real-time supply, consumed stock, and reorder alerts per unit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showInventoryItemDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Stock Item'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(inventoryCategoryFilterProvider.notifier)
                              .state = val;
                        }
                      },
                      items: categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextFormField(
                      initialValue: searchQuery,
                      onChanged: (val) => ref
                          .read(inventorySearchProvider.notifier)
                          .state = val,
                      decoration: InputDecoration(
                        hintText: 'Search stock...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Low Stock Only'),
                  selected: lowStockOnly,
                  onSelected: (selected) {
                    ref.read(inventoryLowStockFilterProvider.notifier).state =
                        selected;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading inventory: $err')),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Supplies Found',
                      message:
                          'Add a stock item or clear filters to view supplies.',
                    );
                  }
                  return isDesktop
                      ? _buildTableView(context, ref, items)
                      : _buildListView(context, ref, items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView(
    BuildContext context,
    WidgetRef ref,
    List<InventoryItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Medicine / Item')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Initial Supply')),
            DataColumn(label: Text('Consumed')),
            DataColumn(label: Text('Remaining Stock')),
            DataColumn(label: Text('Utilization')),
            DataColumn(label: Text('Reorder')),
            DataColumn(label: Text('Actions')),
          ],
          rows: items.map((item) {
            final isLow = item.isLowStock;
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.medicineName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isLow
                              ? AppColors.errorLight
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item.unitName,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(item.category)),
                DataCell(Text('${item.availableStock} ${item.unit}')),
                DataCell(Text('${item.consumed} ${item.unit}')),
                DataCell(
                  Text(
                    '${item.remaining} ${item.unit}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isLow ? AppColors.errorLight : AppColors.textPrimary,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 110,
                    child: LinearProgressIndicator(
                      value: item.consumptionPercent / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLow ? AppColors.errorLight : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                DataCell(StatusBadge.fromString(isLow ? 'low' : 'normal')),
                DataCell(
                  TextButton(
                    onPressed: () => _showConsumeDialog(context, ref, item),
                    child: const Text('Consume'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<InventoryItem> items,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLow = item.isLowStock;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              item.medicineName,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isLow ? AppColors.errorLight : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Category: ${item.category} | Used: ${item.consumed}/${item.availableStock} ${item.unit}',
            ),
            trailing: TextButton(
              onPressed: () => _showConsumeDialog(context, ref, item),
              child: const Text('Consume'),
            ),
          ),
        );
      },
    );
  }

  void _showConsumeDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) {
    final quantityCtrl = TextEditingController(text: '1');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consume ${item.medicineName}'),
        content: TextField(
          controller: quantityCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity consumed (${item.unit})',
            helperText: 'Remaining now: ${item.remaining} ${item.unit}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityCtrl.text) ?? 0;
              if (quantity <= 0) return;
              await ref
                  .read(inventoryProvider.notifier)
                  .consumeItem(item, quantity);
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(analyticsProvider);
              ref.read(alertsProvider.notifier).refresh();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showInventoryItemDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General');
    final stockCtrl = TextEditingController(text: '100');
    final thresholdCtrl = TextEditingController(text: '20');
    final unitCtrl = TextEditingController(text: 'Units');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Medicine / item name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Available stock'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: thresholdCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Low threshold'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final stock = int.tryParse(stockCtrl.text) ?? 0;
              final threshold = int.tryParse(thresholdCtrl.text) ?? 0;
              if (nameCtrl.text.trim().isEmpty || stock <= 0) return;
              final item = InventoryItem(
                id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                medicineName: nameCtrl.text.trim(),
                category: categoryCtrl.text.trim().isEmpty
                    ? 'General'
                    : categoryCtrl.text.trim(),
                unitId: 'unit_001',
                unitName: 'Northern Plains Mobile Unit',
                availableStock: stock,
                consumed: 0,
                remaining: stock,
                unit: unitCtrl.text.trim().isEmpty
                    ? 'Units'
                    : unitCtrl.text.trim(),
                lowStockThreshold: threshold,
                isLowStock: stock <= threshold,
                lastUpdated: DateTime.now(),
              );
              await ref.read(inventoryProvider.notifier).saveItem(item);
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(analyticsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}
