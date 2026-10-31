import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_card.dart';

/// A [DataTable] in a card that fills the width and scrolls sideways when
/// there are more columns than room.
///
/// With a bounded height it fills it and scrolls its rows; inside a scroll
/// view it takes the rows' full height and the page scrolls instead.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.footer,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fill = constraints.hasBoundedHeight;
          final table = DataTable(
            showCheckboxColumn: false,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            columns: columns,
            rows: rows,
          );
          final scroller = Scrollbar(
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: fill
                    ? SingleChildScrollView(padding: const EdgeInsets.only(bottom: AppSpacing.s8), child: table)
                    : Padding(padding: const EdgeInsets.only(bottom: AppSpacing.s8), child: table),
              ),
            ),
          );
          return Column(
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (fill) Expanded(child: scroller) else scroller,
              if (footer != null) ...[const Divider(), footer!],
            ],
          );
        },
      ),
    );
  }
}

/// "51–100 of 1,234" with previous / next, under a paged table.
class TablePager extends StatelessWidget {
  const TablePager({super.key, required this.page, required this.pageSize, required this.total, required this.onPage});

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = (total / pageSize).ceil();
    final from = total == 0 ? 0 : page * pageSize + 1;
    final to = ((page + 1) * pageSize).clamp(0, total);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$from–$to of $total', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: AppSpacing.s8),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Iconsax.arrow_left_2_copy, size: 18),
            onPressed: page > 0 ? () => onPage(page - 1) : null,
          ),
          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Iconsax.arrow_right_3_copy, size: 18),
            onPressed: page < pages - 1 ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// One choice in a [ChipFilterBar].
class ChipOption<T> {
  const ChipOption(this.value, this.label, {this.count});

  final T value;
  final String label;
  final int? count;
}

/// A scrollable row of single-choice chips, with "All" first.
class ChipFilterBar<T> extends StatelessWidget {
  const ChipFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
    this.allCount,
  });

  final List<ChipOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String allLabel;
  final int? allCount;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int? count, bool isSelected, VoidCallback onTap) => Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
          child: ChoiceChip(
            label: Text(count == null ? label : '$label  $count'),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.ink),
            onSelected: (_) => onTap(),
          ),
        );
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(allLabel, allCount, selected == null, () => onSelected(null)),
          for (final o in options) chip(o.label, o.count, selected == o.value, () => onSelected(selected == o.value ? null : o.value)),
        ],
      ),
    );
  }
}
