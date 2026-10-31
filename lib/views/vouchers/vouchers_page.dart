import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/vouchers/voucher_form_page.dart';
import 'package:warsha_app/models/voucher.dart';
import 'package:warsha_app/view_models/vouchers_v_m.dart';

/// Promo codes for the online store.
class VouchersPage extends StatelessWidget {
  const VouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VouchersVM>();
    final vouchers = vm.vouchers;
    return ModulePage(
      title: 'Promo codes',
      subtitle: vm.hasLoaded ? '${vm.liveCount} live now · ${Fmt.count(vm.allVouchers.length, 'code')}' : 'Discount codes for the store',
      primaryAction: PageAction(label: 'New code', icon: Iconsax.add_copy, onPressed: () => openVoucherForm(context)),
      actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: AppSearchField(hint: 'Search codes', initialValue: vm.query, onChanged: vm.setQuery),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: vouchers.isEmpty,
        empty: vm.query.trim().isNotEmpty
            ? EmptyView.noMatch(vm.query)
            : EmptyView(
                icon: Iconsax.ticket_discount_copy,
                title: 'No promo codes yet',
                message: 'Create a code like RAMADAN10 and share it with your customers.',
                actionLabel: 'New code',
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
        VoucherState.active => ('Live', Tone.success),
        VoucherState.scheduled => ('Starts ${Fmt.shortDate(voucher.startDate)}', Tone.info),
        VoucherState.expired => ('Expired', Tone.neutral),
        VoucherState.usedUp => ('Used up', Tone.neutral),
        VoucherState.off => ('Off', Tone.neutral),
      };

  Future<void> _toggle(BuildContext context, bool v) async {
    final vm = context.read<VouchersVM>();
    final ok = await vm.setActive(voucher, v);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: v ? '${voucher.code} is on.' : '${voucher.code} is off.');
  }

  Future<void> _delete(BuildContext context) async {
    final vm = context.read<VouchersVM>();
    final ok = await confirmAction(context, title: 'Delete ${voucher.code}?', message: 'Customers will no longer be able to use it.', confirmLabel: 'Delete');
    if (!ok || !context.mounted) return;
    final deleted = await vm.delete(voucher);
    if (context.mounted) reportResult(context, ok: deleted, errorMessage: vm.errorMessage, success: '${voucher.code} deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final v = voucher;
    final (stateLabel, tone) = _state();
    final off = v.kind == DiscountKind.percentage
        ? '${Fmt.number(v.value)}% off${v.maxDiscount != null ? ' (up to ${Fmt.money(v.maxDiscount)})' : ''}'
        : '${Fmt.money(v.value)} off';
    final saving = context.select<VouchersVM, bool>((vm) => vm.isSaving);
    return EntityTile(
      dimmed: tone == Tone.neutral,
      leading: const IconBadge(Iconsax.ticket_discount_copy),
      title: v.code,
      subtitle: [
        off,
        if (v.minOrder > 0) 'orders from ${Fmt.money(v.minOrder)}',
        v.endDate == null ? 'no end date' : 'until ${Fmt.date(v.endDate)}',
      ].join(' · '),
      meta: [
        StatusPill(label: stateLabel, tone: tone),
        StatusPill(label: v.usageLimit == null ? 'Used ${v.usageCount}×' : 'Used ${v.usageCount} of ${v.usageLimit}', icon: Iconsax.repeat_copy),
      ],
      trailing: Tooltip(
        message: v.active ? 'Turn off' : 'Turn on',
        child: Switch(value: v.active, onChanged: saving ? null : (x) => _toggle(context, x)),
      ),
      actions: [
        RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openVoucherForm(context, voucher: v)),
        RowAction(label: 'Delete', icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context)),
      ],
      onTap: () => openVoucherForm(context, voucher: v),
    );
  }
}
