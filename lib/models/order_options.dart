import 'package:warsha_app/core/l10n/app_locale.dart';
/// A choice in the order form's dropdowns: the value stored on the order and
/// the label staff see.
class OrderOption {
  const OrderOption(this.value, this.labelEn);

  final String value;
  /// English; shown through [label] in the current language.
  final String labelEn;
  String get label => tr(labelEn);
}

/// Where orders come from. Older orders may hold other values; forms keep
/// those as they are.
const orderSources = [
  OrderOption('facebook', 'Facebook'),
  OrderOption('instagram', 'Instagram'),
  OrderOption('tiktok', 'TikTok'),
  OrderOption('whatsapp', 'WhatsApp'),
  OrderOption('ecommerce', 'Online store'),
  OrderOption('walk-in', 'Walk-in'),
];

const paymentMethods = [
  OrderOption('cash', 'Cash on delivery'),
  OrderOption('instapay', 'InstaPay'),
  OrderOption('vodafone cash', 'Vodafone Cash'),
  OrderOption('card', 'Card'),
  OrderOption('bank transfer', 'Bank transfer'),
];

/// The label for a stored [value] ("ecommerce" → "Online store").
String optionLabel(List<OrderOption> options, String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty || v == '-') return '—';
  for (final o in options) {
    if (o.value == v.toLowerCase()) return o.label;
  }
  if (v.toLowerCase() == 'e-commerce') return tr('Online store');
  // Older or store-made values ("website") show as they are, translated when known.
  return tr(v[0].toUpperCase() + v.substring(1));
}
