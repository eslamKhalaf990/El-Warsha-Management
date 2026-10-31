import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/voucher.dart';

/// Promo codes (backend: VoucherController under `/vouchers`).
class VouchersService {
  VouchersService(this._api);

  final ApiClient _api;

  Future<List<Voucher>> list() async => readList(await _api.get('vouchers')).map(Voucher.fromJson).toList();

  Future<Voucher> create(VoucherRequest r) async =>
      Voucher.fromJson(readMap(await _api.post('vouchers', body: r.toJson())) ?? const {});

  Future<Voucher> update(int id, VoucherRequest r) async =>
      Voucher.fromJson(readMap(await _api.put('vouchers/$id', body: r.toJson())) ?? const {});

  Future<void> delete(int id) => _api.delete('vouchers/$id');
}
