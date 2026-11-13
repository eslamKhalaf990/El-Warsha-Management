import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/transaction_cateogry.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

// Transaction types as the API stores them (shown through their own labels).
const deposit = 'Deposit';
const withdrawal = 'Withdrawal';

/// Records money in or out of an account; [account] / [type] preselect them.
Future<void> openTransactionForm(BuildContext context, {BankAccount? account, String type = deposit}) {
  final vm = context.read<AccountingVM>()..clearError();
  return showFormDialog(
    context,
    draft: () => FormDraft(values: {
      'account': account ?? vm.accountsBalance?.firstOrNull,
      'type': type,
      'categoryId': vm.allTransactionCategories?.firstOrNull?.categoryID,
    }),
    dialog: const _TransactionDialog(),
  );
}

class _TransactionDialog extends StatelessWidget {
  const _TransactionDialog();

  Future<void> _save(BuildContext context) async {
    final vm = context.read<AccountingVM>();
    final d = context.read<FormDraft>();
    final account = d.value<BankAccount>('account');
    if (account == null) return showError(context, tr('Choose an account.'));
    final type = d.value<String>('type')!;
    final ok = await vm.addTransaction(
      account: account,
      transactionType: type,
      amountText: d.text('amount'),
      description: d.text('description'),
      categoryId: d.value<int>('categoryId'),
    );
    if (!context.mounted) return;
    reportResult(
      context,
      ok: ok,
      pop: true,
      errorMessage: vm.errorMessage,
      success: type == deposit ? tr('Deposit saved.') : tr('Withdrawal saved.'),
      fieldError: vm.fieldError,
      fields: const ['amount', 'description'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final d = context.watch<FormDraft>();
    final accounts = vm.accountsBalance ?? const <BankAccount>[];
    final categories = vm.allTransactionCategories ?? const <TransactionCategory>[];
    final type = d.value<String>('type')!;
    final account = d.value<BankAccount>('account');

    return FormDialog(
      title: tr('New transaction'),
      icon: type == deposit ? Iconsax.money_recive_copy : Iconsax.money_send_copy,
      saveLabel: type == deposit ? tr('Save deposit') : tr('Save withdrawal'),
      saving: vm.isSaving,
      onSave: () => _save(context),
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: deposit, label: Text(tr('Money in')), icon: const Icon(Iconsax.money_recive_copy, size: 18)),
            ButtonSegment(value: withdrawal, label: Text(tr('Money out')), icon: const Icon(Iconsax.money_send_copy, size: 18)),
          ],
          selected: {type},
          onSelectionChanged: (s) {
            d.set('type', s.first);
            vm.clearError();
          },
        ),
        AppDropdown<BankAccount>(
          label: tr('Account'),
          required: true,
          icon: Iconsax.bank_copy,
          items: accounts,
          value: account,
          itemLabel: (a) => '${a.name} · ${Fmt.money(a.currentBalance)}',
          onChanged: (a) {
            d.set('account', a);
            vm.clearError();
          },
        ),
        AppTextField.money(
          label: tr('Amount'),
          required: true,
          autofocus: true,
          controller: d.controller('amount'),
          errorText: vm.fieldError('amount'),
          helperText: type == withdrawal && account != null ? tr('Available: {0}', [Fmt.money(account.currentBalance)]) : null,
          onChanged: (_) => vm.clearError(),
        ),
        AppDropdown<int>(
          label: tr('Category'),
          icon: Iconsax.category_2_copy,
          items: [for (final c in categories) c.categoryID],
          value: d.value<int>('categoryId'),
          itemLabel: (id) => categories.firstWhere((c) => c.categoryID == id).categoryName,
          onChanged: (id) => d.set('categoryId', id),
        ),
        AppTextField(
          label: tr('Description'),
          icon: Iconsax.note_1_copy,
          hintText: tr('What was it for?'),
          controller: d.controller('description'),
          errorText: vm.fieldError('description'),
          maxLength: AccountingVM.descriptionMaxLength,
          onChanged: (_) => vm.clearError(),
          onSubmitted: (_) => _save(context),
        ),
      ],
    );
  }
}

/// Asks for the owner password and shows the safe.
Future<void> openSafe(BuildContext context) {
  context.read<AccountingVM>().clearError();
  return showFormDialog(context, draft: FormDraft.new, dialog: const _UnlockDialog());
}

class _UnlockDialog extends StatelessWidget {
  const _UnlockDialog();

  Future<void> _open(BuildContext context) async {
    final vm = context.read<AccountingVM>();
    final ok = await vm.unlockSafe(context.read<FormDraft>().text('password'));
    if (ok && context.mounted) {
      Navigator.pop(context);
      showSuccess(context, tr('Safe opened for this session.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final d = context.read<FormDraft>();
    final error = vm.fieldError('password') ?? (vm.error != null && !vm.loadFailed ? vm.errorMessage : null);
    return FormDialog(
      title: tr('Open the safe'),
      icon: Iconsax.security_safe_copy,
      saveLabel: tr('Open'),
      saving: vm.isSaving,
      onSave: () => _open(context),
      children: [
        AppText.bodySmall(
          tr('The owner’s safe stays hidden until the owner password is entered. The first password ever entered becomes the safe’s password.'),
          color: AppColors.muted,
        ),
        AppTextField(
          label: tr('Owner password'),
          icon: Iconsax.key_copy,
          obscureText: true,
          autofocus: true,
          controller: d.controller('password'),
          errorText: error,
          textInputAction: TextInputAction.done,
          onChanged: (_) => vm.clearError(),
          onSubmitted: (_) => _open(context),
        ),
      ],
    );
  }
}

/// Deletes every transaction after the user types RESET (and the owner
/// password when the safe has one).
Future<void> openReset(BuildContext context) {
  context.read<AccountingVM>().clearError();
  return showFormDialog(context, draft: FormDraft.new, dialog: const _ResetDialog());
}

class _ResetDialog extends StatelessWidget {
  const _ResetDialog();

  Future<void> _reset(BuildContext context) async {
    final d = context.read<FormDraft>();
    if (d.text('confirm').trim().toUpperCase() != 'RESET') {
      return showError(context, tr('Type RESET to confirm.'));
    }
    final vm = context.read<AccountingVM>();
    final ok = await vm.resetAll(ownerPassword: d.text('password'));
    if (context.mounted) reportResult(context, ok: ok, pop: true, errorMessage: vm.errorMessage, success: tr('All transactions were reset.'));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final d = context.read<FormDraft>();
    return FormDialog(
      title: tr('Reset all transactions?'),
      icon: Iconsax.danger_copy,
      saveLabel: tr('Reset everything'),
      danger: true,
      saving: vm.isSaving,
      onSave: () => _reset(context),
      children: [
        InlineBanner(
          message: tr('Every transaction is deleted and every balance goes back to 0. This can’t be undone.'),
          tone: Tone.error,
          icon: Iconsax.warning_2_copy,
        ),
        AppTextField(
          label: tr('Type RESET to confirm'),
          icon: Iconsax.edit_2_copy,
          controller: d.controller('confirm'),
          autofocus: true,
        ),
        if (!vm.isSafeUnlocked)
          AppTextField(
            label: tr('Owner password'),
            icon: Iconsax.key_copy,
            obscureText: true,
            helperText: tr('Needed once the safe has a password.'),
            controller: d.controller('password'),
          ),
      ],
    );
  }
}
