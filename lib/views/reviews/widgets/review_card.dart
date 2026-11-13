import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/review.dart';
import 'package:warsha_app/view_models/reviews_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

extension ReviewStatusTone on ReviewStatus {
  Tone get tone => switch (this) {
        ReviewStatus.pending => Tone.warning,
        ReviewStatus.approved => Tone.success,
        ReviewStatus.rejected => Tone.neutral,
        ReviewStatus.resolved => Tone.info,
      };
}

/// 1–5 stars; [rating] 0 shows nothing.
class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Semantics(
      label: tr('{0} out of 5 stars', [rating]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= rating ? Iconsax.star_1 : Iconsax.star_1_copy, size: size, color: AppColors.champagne),
        ],
      ),
    );
  }
}

/// A review with everything needed to moderate it in place.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  Future<void> _run(BuildContext context, Future<bool> Function(ReviewsVM vm) action, String success) async {
    final vm = context.read<ReviewsVM>();
    final ok = await action(vm);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: success);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: tr('Delete review?'),
      message: tr('{0}’s review and its replies will be removed for good.', [review.customerName]),
      confirmLabel: tr('Delete'),
    );
    if (ok && context.mounted) await _run(context, (vm) => vm.delete(review), tr('Review deleted.'));
  }

  @override
  Widget build(BuildContext context) {
    final r = review;
    final saving = context.select<ReviewsVM, bool>((vm) => vm.isSaving);
    final about = [
      if (r.productName != null) r.productName!,
      if (r.orderId != null) tr('Order #{0}', [r.orderId]),
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(Fmt.initials(r.customerName)),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.label(r.customerName, maxLines: 1),
                    AppText.caption([Fmt.dateTime(r.createdAt), if (r.customerPhone != null) r.customerPhone!].join(' · ')),
                  ],
                ),
              ),
              StatusPill(label: r.status.label, tone: r.status.tone),
              RowActions(
                [
                  RowAction(label: tr('Reply'), icon: Iconsax.message_edit_copy, onPressed: () => openReply(context, r)),
                  RowAction(label: tr('Delete'), icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context)),
                ],
                forceMenu: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Stars(r.rating),
              StatusPill(label: r.typeLabel, tone: r.type.toUpperCase() == 'COMPLAINT' ? Tone.error : Tone.brand),
              if (about.isNotEmpty) StatusPill(label: about, icon: Iconsax.box_1_copy),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          if ((r.subject ?? '').trim().isNotEmpty) AppText.titleSmall(r.subject!),
          AppText.body(r.comment),
          if ((r.adminReply ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            AppCard(
              variant: AppCardVariant.blush,
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(tr('Your reply · {0} · {1}', [r.repliedBy ?? tr('Admin'), Fmt.date(r.repliedAt)]), color: AppColors.burgundy),
                  const SizedBox(height: 2),
                  AppText.bodySmall(r.adminReply!),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          const Divider(),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (r.status != ReviewStatus.approved)
                AppButton.primary(
                  label: tr('Approve'),
                  icon: Iconsax.tick_circle_copy,
                  compact: true,
                  onPressed: saving ? null : () => _run(context, (vm) => vm.setStatus(r, ReviewStatus.approved), tr('Approved and published.')),
                ),
              if (r.status == ReviewStatus.pending || r.status == ReviewStatus.approved)
                AppButton.secondary(
                  label: tr('Reject'),
                  icon: Iconsax.close_circle_copy,
                  compact: true,
                  onPressed: saving ? null : () => _run(context, (vm) => vm.setStatus(r, ReviewStatus.rejected), tr('Review rejected.')),
                ),
              if (r.type.toUpperCase() != 'PRODUCT' && r.status != ReviewStatus.resolved)
                AppButton.text(
                  label: tr('Mark resolved'),
                  icon: Iconsax.task_square_copy,
                  compact: true,
                  onPressed: saving ? null : () => _run(context, (vm) => vm.setStatus(r, ReviewStatus.resolved), tr('Marked as resolved.')),
                ),
              FilterChip(
                label: Text(tr('On the store')),
                avatar: const Icon(Iconsax.global_copy, size: 16),
                selected: r.isPublic,
                onSelected: saving ? null : (v) => _run(context, (vm) => vm.setPublic(r, v), v ? tr('Shown on the store.') : tr('Hidden from the store.')),
              ),
              FilterChip(
                label: Text(tr('Featured')),
                avatar: const Icon(Iconsax.star_1_copy, size: 16),
                selected: r.isFeatured,
                onSelected: saving ? null : (v) => _run(context, (vm) => vm.setFeatured(r, v), v ? tr('Featured on the home page.') : tr('No longer featured.')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Writes the store's public answer to [review].
Future<void> openReply(BuildContext context, Review review) {
  context.read<ReviewsVM>().clearError();
  return showFormDialog(
    context,
    draft: () => FormDraft(text: {'reply': review.adminReply}),
    dialog: _ReplyDialog(review: review),
  );
}

class _ReplyDialog extends StatelessWidget {
  const _ReplyDialog({required this.review});

  final Review review;

  Future<void> _send(BuildContext context) async {
    final vm = context.read<ReviewsVM>();
    final ok = await vm.reply(review, context.read<FormDraft>().text('reply'));
    if (context.mounted) {
      reportResult(context, ok: ok, pop: true, errorMessage: vm.errorMessage, success: tr('Reply posted.'), fieldError: vm.fieldError, fields: const ['reply']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewsVM>();
    return FormDialog(
      title: tr('Reply to {0}', [review.customerName]),
      icon: Iconsax.message_edit_copy,
      saveLabel: tr('Post reply'),
      saving: vm.isSaving,
      onSave: () => _send(context),
      children: [
        AppCard(variant: AppCardVariant.ivory, padding: const EdgeInsets.all(AppSpacing.s12), child: AppText.bodySmall(review.comment)),
        AppTextField(
          label: tr('Your reply'),
          icon: Iconsax.message_text_copy,
          helperText: tr('Shown under the review on the store.'),
          controller: context.read<FormDraft>().controller('reply'),
          errorText: vm.fieldError('reply'),
          maxLength: ReviewsVM.replyMaxLength,
          maxLines: 5,
          autofocus: true,
          onChanged: (_) => vm.clearError(),
        ),
      ],
    );
  }
}
