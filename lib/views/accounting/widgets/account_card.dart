import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/accounting/accounting_dialogs.dart';
import 'package:warsha_app/models/account_balance.dart';

/// An account's balance with quick "money in / money out" buttons.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account});

  final BankAccount account;

  IconData get _icon {
    if (account.ownerSafe) return Iconsax.security_safe_copy;
    final t = '${account.accountType} ${account.name}'.toLowerCase();
    if (t.contains('cash') && !t.contains('vodafone')) return Iconsax.money_3_copy;
    if (t.contains('wallet') || t.contains('vodafone') || t.contains('instapay')) return Iconsax.mobile_copy;
    return Iconsax.bank_copy;
  }

  @override
  Widget build(BuildContext context) {
    final a = account;
    return StatCard(
      label: a.name,
      value: Fmt.money(a.currentBalance),
      icon: _icon,
      tone: a.ownerSafe ? Tone.warning : Tone.brand,
      caption: a.ownerSafe ? 'Owner’s safe' : (a.accountType.isEmpty ? null : a.accountType),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Money in',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Iconsax.money_recive_copy, size: 18, color: AppStatusColors.successText),
            onPressed: () => openTransactionForm(context, account: a, type: deposit),
          ),
          IconButton(
            tooltip: 'Money out',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Iconsax.money_send_copy, size: 18, color: AppStatusColors.errorText),
            onPressed: () => openTransactionForm(context, account: a, type: withdrawal),
          ),
        ],
      ),
    );
  }
}
