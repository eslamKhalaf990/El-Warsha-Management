import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/vouchers/voucher_form_page.dart';
import 'package:warsha_app/models/voucher.dart';
import 'package:warsha_app/view_models/vouchers_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// Promo codes for the online store.
class VouchersPage extends StatelessWidget {
  const VouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VouchersVM>();
    final vouchers = vm.vouchers;
    return ModulePage(
      title: tr('Promo codes'),
      subtitle: vm.hasLoaded ? tr('{0} live now · {1}', [vm.liveCount, Fmt.count(vm.allVouchers.length, 'code')]) : tr('Discount codes for the store'),
      primaryAction: PageAction(label: tr('New code'), icon: Iconsax.add_copy, onPressed: () => openVoucherForm(context)),
      actions: [IconButton(tooltip: tr('Refresh'), icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: AppSearchField(hint: tr('Search codes'), initialValue: vm.query, onChanged: vm.setQuery),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: vouchers.isEmpty,
        empty: vm.query.trim().isNotEmpty
            ? EmptyView.noMatch(vm.query)
            : EmptyView(
                icon: Iconsax.ticket_discount_copy,
                title: tr('No promo codes yet'),
                message: tr('Create a code like RAMADAN10 and share it with your customers.'),
                actionLabel: tr('New code'),
                onAction: () => openVoucherForm(context),
              ),
        builder: (context) => context.isCompact
            ? TileList(items: vouchers, onRefresh: vm.fetch, itemBuilder: (_, v) => _VoucherTile(voucher: v))
            : GridView.builder(
                padding: listPadding(context),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 520,
                  mainAxisExtent: 112,
                  crossAxisSpacing: AppSpacing.s12,
                  mainAxisSpacing: AppSpacing.s12,
                ),
                itemCount: vouchers.length,
                itemBuilder: (_, i) => _VoucherTile(voucher: vouchers[i]),
              ),
      ),
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({required this.voucher});

  final Voucher voucher;

  (String, Tone) _state() => switch (voucher.stateOn(DateTime.now())) {
        VoucherState.active => (tr('Live'), Tone.success),
        VoucherState.scheduled => (tr('Starts {0}', [Fmt.shortDate(voucher.startDate)]), Tone.info),
        VoucherState.expired => (tr('Expired'), Tone.neutral),
        VoucherState.usedUp => (tr('Used up'), Tone.neutral),
        VoucherState.off => (tr('Off'), Tone.neutral),
      };

  Future<void> _toggle(BuildContext context, bool v) async {
    final vm = context.read<VouchersVM>();
    final ok = await vm.setActive(voucher, v);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: v ? tr('{0} is on.', [voucher.code]) : tr('{0} is off.', [voucher.code]));
  }

  Future<void> _delete(BuildContext context) async {
    final vm = context.read<VouchersVM>();
    final ok = await confirmAction(context, title: tr('Delete {0}?', [voucher.code]), message: tr('Customers will no longer be able to use it.'), confirmLabel: tr('Delete'));
    if (!ok || !context.mounted) return;
    final deleted = await vm.delete(voucher);
    if (context.mounted) reportResult(context, ok: deleted, errorMessage: vm.errorMessage, success: tr('{0} deleted.', [voucher.code]));
  }

  @override
  Widget build(BuildContext context) {
    final v = voucher;
    final (stateLabel, tone) = _state();
    final off = v.kind == DiscountKind.percentage
        ? tr('{0}% off{1}', [Fmt.number(v.value), v.maxDiscount != null ? tr(' (up to {0})', [Fmt.money(v.maxDiscount)]) : ''])
        : tr('{0} off', [Fmt.money(v.value)]);
    final saving = context.select<VouchersVM, bool>((vm) => vm.isSaving);
    return EntityTile(
      dimmed: tone == Tone.neutral,
      leading: const IconBadge(Iconsax.ticket_discount_copy),
      title: v.code,
      subtitle: [
        off,
        if (v.minOrder > 0) tr('orders from {0}', [Fmt.money(v.minOrder)]),
        v.endDate == null ? tr('no end date') : tr('until {0}', [Fmt.date(v.endDate)]),
      ].join(' · '),
      meta: [
        StatusPill(label: stateLabel, tone: tone),
        StatusPill(label: v.usageLimit == null ? tr('Used {0}×', [v.usageCount]) : tr('Used {0} of {1}', [v.usageCount, v.usageLimit]), icon: Iconsax.repeat_copy),
      ],
      trailing: Tooltip(
        message: v.active ? tr('Turn off') : tr('Turn on'),
        child: Switch(value: v.active, onChanged: saving ? null : (x) => _toggle(context, x)),
      ),
      actions: [
        RowAction(label: tr('Edit'), icon: Iconsax.edit_2_copy, onPressed: () => openVoucherForm(context, voucher: v)),
        RowAction(label: tr('Delete'), icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context)),
      ],
      onTap: () => openVoucherForm(context, voucher: v),
    );
  }
}
