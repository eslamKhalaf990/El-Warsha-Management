import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/orders/order_actions.dart';
import 'package:warsha_app/views/orders/widgets/order_pickers.dart';
import 'package:warsha_app/views/orders/widgets/order_totals_view.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/models/order_item_model.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_options.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/order_draft.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

/// Fields the order form shows next to their input.
bool _isFormField(String field) =>
    const {'customerId', 'items', 'paymentMethod', 'orderSource', 'downPayment', 'discount', 'delivery', 'notes', 'bankAccountId'}
        .contains(field) ||
    RegExp(r'^items\[\d+\]\.quantity$').hasMatch(field);

/// Opens the new-order form, or the edit form for [order].
Future<void> openOrderForm(BuildContext context, {OrderModel? order}) {
  context.read<OrderVM>().clearError();
  final unitDiscounts = context.read<ProductVM>().unitDiscounts;
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<OrderDraft>(
        create: (_) => OrderDraft(order: order, unitDiscounts: unitDiscounts),
        child: const OrderFormPage(),
      ),
    ),
  );
}

/// Add or edit an order: customer and items on the left, payment and the
/// live total on the right (stacked on phones).
class OrderFormPage extends StatelessWidget {
  const OrderFormPage({super.key});

  Future<void> _save(BuildContext context) async {
    final vm = context.read<OrderVM>();
    final d = context.read<OrderDraft>();
    final form = d.form;
    if (!vm.checkOrder(form)) return showOrderError(context, vm.lastError, isShownField: _isFormField);

    if (d.isEdit) {
      final ok = await vm.saveOrder(d.editingId!, form);
      if (!context.mounted) return;
      if (!ok) return showOrderError(context, vm.lastError, isShownField: _isFormField);
      refreshAfterOrderChange(context);
      Navigator.pop(context);
      return showSuccess(context, 'Order #${d.editingId} updated.');
    }

    if (form.needsBankAccount && d.bankAccountId == null) {
      vm.fail(ApiException.validation({'bankAccountId': 'Choose the account that received the down payment.'}));
      return;
    }
    final created = await vm.placeOrder(form, bankAccountId: form.needsBankAccount ? d.bankAccountId : null);
    if (!context.mounted) return;
    if (created == null) return showOrderError(context, vm.lastError, isShownField: _isFormField);
    refreshAfterOrderChange(context);
    Navigator.pop(context);
    showSuccess(context, 'Order #${created.orderId} added.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderVM>();
    final d = context.watch<OrderDraft>();

    return FormPage(
      title: d.isEdit ? 'Edit order #${d.editingId}' : 'New order',
      subtitle: d.isEdit ? 'Items, prices and payment can change until the order ships.' : null,
      draft: d,
      saving: vm.isSaving,
      saveLabel: d.isEdit ? 'Save changes' : 'Place order',
      onSave: () => _save(context),
      sections: const [_CustomerSection(), _ItemsSection()],
      aside: const [_PaymentSection(), _SummarySection()],
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection();

  void _select(BuildContext context, CustomerModel c) {
    final price = context.read<ShippingZoneVM>().priceFor(c.governorate);
    context.read<OrderDraft>().selectCustomer(c, deliveryPrice: price);
    context.read<OrderVM>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<OrderDraft>();
    final error = context.watch<OrderVM>().fieldError('customerId');
    final c = d.customer;
    return FormSection(
      title: 'Customer',
      icon: Iconsax.user_copy,
      trailing: c == null ? null : AppButton.text(label: 'Change', compact: true, onPressed: () => d.set('customer', null)),
      children: [
        if (c == null)
          CustomerPicker(errorText: error, onSelected: (c) => _select(context, c))
        else
          AppCard(
            variant: AppCardVariant.ivory,
            child: Row(
              children: [
                InitialsAvatar(Fmt.initials(c.fullName), size: 44),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.label(c.fullName),
                      AppText.caption('${c.phone}  ·  #${c.customerId}'),
                      const SizedBox(height: AppSpacing.s4),
                      AppText.bodySmall(
                        [c.address, c.city, c.governorate].where((s) => s.trim().isNotEmpty).join(', '),
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection();

  @override
  Widget build(BuildContext context) {
    final d = context.watch<OrderDraft>();
    final vm = context.watch<OrderVM>();
    final items = d.items;
    final pieces = items.fold<int>(0, (n, i) => n + i.quantityToOrder);

    return FormSection(
      title: 'Items',
      icon: Iconsax.box_1_copy,
      subtitle: items.isEmpty ? null : '${Fmt.count(items.length, 'line')} · ${Fmt.count(pieces, 'piece')}',
      children: [
        ProductPicker(
          errorText: vm.fieldError('items'),
          onSelected: (p, v) {
            d.addLine(p, variant: v);
            vm.clearError();
          },
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
            child: EmptyView(
              icon: Iconsax.shopping_cart_copy,
              title: 'No items yet',
              message: 'Search above to add the first product.',
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            _LineRow(item: items[i], index: i, error: vm.fieldError('items[$i].quantity')),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.item, required this.index, this.error});

  final OrderItemModel item;
  final int index;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final d = context.read<OrderDraft>();
    final q = item.quantityToOrder;
    final unit = item.unitPrice - item.unitDiscount;
    final compact = context.isCompact;

    final stepper = Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: AppRadius.pillBorderRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: q == 1 ? 'Remove' : 'One less',
            visualDensity: VisualDensity.compact,
            icon: Icon(q == 1 ? Iconsax.trash_copy : Iconsax.minus_copy, size: 16),
            onPressed: () => d.setQuantity(index, q - 1),
          ),
          SizedBox(width: 28, child: AppText.label('$q', align: TextAlign.center)),
          IconButton(
            tooltip: 'One more',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Iconsax.add_copy, size: 16),
            onPressed: () => d.setQuantity(index, q + 1),
          ),
        ],
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label(item.displayName, maxLines: 2),
        AppText.caption(
          item.unitDiscount > 0
              ? '${Fmt.money(unit)} each (−${Fmt.money(item.unitDiscount)})'
              : '${Fmt.money(unit)} each',
        ),
        FieldError(error),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: AppSpacing.s8),
                Row(children: [stepper, const Spacer(), AppText.price(Fmt.money(unit * q))]),
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                stepper,
                SizedBox(width: 120, child: AppText.price(Fmt.money(unit * q), align: TextAlign.end)),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Iconsax.close_circle_copy, size: 18, color: AppColors.muted),
                  onPressed: () => d.removeLine(index),
                ),
              ],
            ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection();

  @override
  Widget build(BuildContext context) {
    final d = context.watch<OrderDraft>();
    final vm = context.watch<OrderVM>();
    final accounts = context.watch<AccountingVM>().accountsBalance ?? const <BankAccount>[];
    final needsAccount = !d.isEdit && d.form.needsBankAccount;

    AppTextField money(String key, String label, IconData icon, {String? helper}) => AppTextField.money(
          label: label,
          icon: icon,
          helperText: helper,
          controller: d.controller(key),
          errorText: vm.fieldError(key),
          onChanged: (_) {
            if (key == 'delivery') d.set('deliveryAuto', false);
            vm.clearError();
            d.touch();
          },
        );

    List<String> withCurrent(List<OrderOption> options, String? current) => [
          for (final o in options) o.value,
          if (current != null && !options.any((o) => o.value == current)) current,
        ];

    return FormSection(
      title: 'Payment',
      icon: Iconsax.wallet_2_copy,
      children: [
        AppDropdown<String>(
          label: 'Came from',
          required: true,
          icon: Iconsax.global_copy,
          items: withCurrent(orderSources, d.value<String>('orderSource')),
          value: d.value<String>('orderSource'),
          itemLabel: (v) => optionLabel(orderSources, v),
          errorText: vm.fieldError('orderSource'),
          onChanged: (v) {
            d.set('orderSource', v);
            vm.clearError();
          },
        ),
        AppDropdown<String>(
          label: 'Payment method',
          required: true,
          icon: Iconsax.card_copy,
          items: withCurrent(paymentMethods, d.value<String>('paymentMethod')),
          value: d.value<String>('paymentMethod'),
          itemLabel: (v) => optionLabel(paymentMethods, v),
          errorText: vm.fieldError('paymentMethod'),
          onChanged: (v) {
            d.set('paymentMethod', v);
            vm.clearError();
          },
        ),
        FieldRow(children: [
          money('delivery', 'Delivery', Iconsax.truck_fast_copy,
              helper: d.value<bool>('deliveryAuto') == true ? 'From the shipping zone' : null),
          money('discount', 'Extra discount', Iconsax.discount_shape_copy, helper: 'On top of product discounts'),
        ]),
        money('downPayment', 'Paid upfront', Iconsax.money_recive_copy),
        if (needsAccount)
          AppDropdown<BankAccount>(
            label: 'Received in',
            required: true,
            icon: Iconsax.bank_copy,
            items: accounts,
            value: accounts.where((a) => a.id == d.bankAccountId).firstOrNull,
            itemLabel: (a) => a.name,
            errorText: vm.fieldError('bankAccountId'),
            onChanged: (a) {
              d.set('bankAccountId', a?.id);
              vm.clearError();
            },
          ),
        AppTextField(
          label: 'Notes',
          icon: Iconsax.note_1_copy,
          hintText: 'Gift wrap, delivery time…',
          controller: d.controller('notes'),
          errorText: vm.fieldError('notes'),
          maxLength: 1000,
          maxLines: 3,
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    final totals = context.watch<OrderDraft>().totals;
    return FormSection(title: 'Summary', icon: Iconsax.receipt_2_copy, children: [OrderTotalsView(totals)]);
  }
}
