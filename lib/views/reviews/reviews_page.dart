import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/reviews/widgets/review_card.dart';
import 'package:warsha_app/models/review.dart';
import 'package:warsha_app/view_models/reviews_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// What customers wrote in the store, waiting ones first.
class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewsVM>();
    final reviews = vm.reviews;
    final counts = vm.statusCounts;
    final waiting = counts[ReviewStatus.pending] ?? 0;
    final avg = vm.averageRating;

    return ModulePage(
      title: tr('Reviews'),
      subtitle: vm.hasLoaded
          ? [
              waiting == 0 ? tr('Nothing waiting') : tr('{0} waiting for you', [waiting]),
              if (avg != null) tr('average {0} ★', [avg.toStringAsFixed(1)]),
            ].join(' · ')
          : tr('Reviews and messages from the store'),
      actions: [IconButton(tooltip: tr('Refresh'), icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: AppSearchField(hint: tr('Search name, product or text'), initialValue: vm.query, onChanged: vm.setQuery)),
            const SizedBox(width: AppSpacing.s12),
            SizedBox(
              width: context.isCompact ? 130 : 180,
              child: AppDropdown<int?>(
                label: tr('Stars'),
                icon: Iconsax.star_1_copy,
                hintText: tr('Any'),
                items: const [null, 5, 4, 3, 2, 1],
                value: vm.ratingFilter,
                itemLabel: (r) => r == null ? tr('Any') : '$r ★',
                onChanged: vm.setRatingFilter,
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.s12),
          ChipFilterBar<ReviewStatus>(
            allCount: vm.allReviews.length,
            options: [for (final s in ReviewStatus.values) ChipOption(s, s.label, count: counts[s] ?? 0)],
            selected: vm.statusFilter,
            onSelected: vm.setStatusFilter,
          ),
        ],
      ),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: reviews.isEmpty,
        empty: vm.statusFilter == ReviewStatus.pending && vm.query.trim().isEmpty && vm.ratingFilter == null
            ? EmptyView(
                icon: Iconsax.tick_circle_copy,
                title: tr('All caught up'),
                message: tr('New reviews from the store will wait here for you.'),
              )
            : EmptyView(icon: Iconsax.message_text_copy, title: tr('No reviews match'), message: tr('Try other filters.')),
        builder: (context) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: TileList(items: reviews, onRefresh: vm.fetch, itemBuilder: (_, r) => ReviewCard(review: r)),
          ),
        ),
      ),
    );
  }
}
