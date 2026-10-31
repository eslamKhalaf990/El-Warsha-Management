import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/voucher.dart';
import 'package:warsha_app/view_models/vouchers_v_m.dart';

/// Opens the add form, or the edit form for [voucher].
Future<void> openVoucherForm(BuildContext context, {Voucher? voucher}) {
  context.read<VouchersVM>().clearError();
  String plain(double? v) => v == null || v == 0 ? '' : Fmt.number(v).replaceAll(',', '');
  final today = DateTime.now();
  return pushFormPage(
    context,
    draft: () => FormDraft(
      text: {
        'code': voucher?.code,
        'discountValue': voucher == null ? null : plain(voucher.value),
        'minOrderAmount': plain(voucher?.minOrder),
        'maxDiscountAmount': plain(voucher?.maxDiscount),
        'maxUsageLimit': voucher?.usageLimit?.toString(),
      },
      values: {
        'kind': voucher?.kind ?? DiscountKind.percentage,
        'startDate': voucher?.startDate ?? DateTime(today.year, today.month, today.day),
        'endDate': voucher?.endDate,
        'active': voucher?.active ?? true,
      },
    ),
    page: VoucherFormPage(voucher: voucher),
  );
}

class VoucherFormPage extends StatelessWidget {
  const VoucherFormPage({super.key, this.voucher});

  final Voucher? voucher;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<VouchersVM>();
    final d = context.read<FormDraft>();
    final ok = await vm.save(
      VoucherForm(
        code: d.text('code'),
        kind: d.value<DiscountKind>('kind')!,
        value: d.text('discountValue'),
        minOrder: d.text('minOrderAmount'),
        maxDiscount: d.text('maxDiscountAmount'),
        usageLimit: d.text('maxUsageLimit'),
        startDate: d.value<DateTime>('startDate'),
        endDate: d.value<DateTime>('endDate'),
        active: d.flag('active'),
      ),
      editing: voucher,
    );
    if (!context.mounted) return;
    reportResult(
      context,
      ok: ok,
      pop: true,
      errorMessage: vm.errorMessage,
      success: voucher == null ? 'Promo code created.' : 'Promo code updated.',
      fieldError: vm.fieldError,
      fields: VouchersVM.formFields,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VouchersVM>();
    final d = context.watch<FormDraft>();
    final kind = d.value<DiscountKind>('kind')!;
    final percent = kind == DiscountKind.percentage;

    void changed([_]) => vm.clearError();

    return FormPage(
      title: voucher == null ? 'New promo code' : 'Edit ${voucher!.code}',
      subtitle: voucher == null ? null : 'Used ${Fmt.count(voucher!.usageCount, 'time')}',
      draft: d,
      saving: vm.isSaving,
      saveLabel: voucher == null ? 'Create code' : 'Save changes',
      onSave: () => _save(context),
      sections: [
        FormSection(
          title: 'Code & discount',
          icon: Iconsax.ticket_discount_copy,
          children: [
            AppTextField(
              label: 'Code',
              required: true,
              icon: Iconsax.ticket_copy,
              hintText: 'RAMADAN10',
              helperText: 'What customers type at checkout. Saved in capitals.',
              controller: d.controller('code'),
              errorText: vm.fieldError('code'),
              maxLength: VouchersVM.codeMaxLength,
              textDirection: TextDirection.ltr,
              onChanged: changed,
            ),
            SegmentedButton<DiscountKind>(
              segments: const [
                ButtonSegment(value: DiscountKind.percentage, label: Text('Percentage'), icon: Icon(Iconsax.percentage_circle_copy, size: 18)),
                ButtonSegment(value: DiscountKind.fixed, label: Text('Fixed amount'), icon: Icon(Iconsax.money_2_copy, size: 18)),
              ],
              selected: {kind},
              onSelectionChanged: (s) => d.set('kind', s.first),
            ),
            FieldRow(children: [
              percent
                  ? AppTextField(
                      label: 'Discount',
                      required: true,
                      icon: Iconsax.percentage_circle_copy,
                      suffixText: '%',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: moneyInputFormatters,
                      controller: d.controller('discountValue'),
                      errorText: vm.fieldError('discountValue'),
                      onChanged: changed,
                    )
                  : AppTextField.money(
                      label: 'Discount',
                      required: true,
                      controller: d.controller('discountValue'),
                      errorText: vm.fieldError('discountValue'),
                      onChanged: changed,
                    ),
              if (percent)
                AppTextField.money(
                  label: 'Up to',
                  helperText: 'Largest discount per order. Empty = no cap.',
                  controller: d.controller('maxDiscountAmount'),
                  errorText: vm.fieldError('maxDiscountAmount'),
                  onChanged: changed,
                ),
            ]),
          ],
        ),
        FormSection(
          title: 'Rules',
          icon: Iconsax.setting_4_copy,
          children: [
            FieldRow(children: [
              AppTextField.money(
                label: 'Minimum order',
                helperText: 'Empty = any order.',
                controller: d.controller('minOrderAmount'),
                errorText: vm.fieldError('minOrderAmount'),
                onChanged: changed,
              ),
              AppTextField(
                label: 'Usage limit',
                icon: Iconsax.repeat_copy,
                helperText: 'Times it can be used in total. Empty = unlimited.',
                keyboardType: TextInputType.number,
                inputFormatters: intInputFormatters,
                controller: d.controller('maxUsageLimit'),
                errorText: vm.fieldError('maxUsageLimit'),
                onChanged: changed,
              ),
            ]),
            FieldRow(children: [
              AppDateField(
                label: 'Starts',
                required: true,
                value: d.value<DateTime>('startDate'),
                errorText: vm.fieldError('startDate'),
                onChanged: (v) => d
                  ..set('startDate', v)
                  ..touch(),
              ),
              AppDateField(
                label: 'Ends',
                hintText: 'Never',
                clearable: true,
                value: d.value<DateTime>('endDate'),
                errorText: vm.fieldError('endDate'),
                onChanged: (v) => d.set('endDate', v),
              ),
            ]),
            AppSwitchTile(
              title: 'Active',
              subtitle: d.flag('active') ? 'Customers can use it within the dates.' : 'Paused: customers get “inactive”.',
              value: d.flag('active'),
              onChanged: (v) => d.set('active', v),
            ),
          ],
        ),
      ],
    );
  }
}
