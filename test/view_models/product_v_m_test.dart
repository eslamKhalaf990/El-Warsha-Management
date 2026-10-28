import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/services/product_variants_service.dart';
import 'package:warsha_app/services/products_service.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';

ProductModel product(String id, String name, {String discount = '0', String? sku}) => ProductModel.get(
      name: name,
      id: id,
      productDescription: '',
      buyingPrice: '100',
      sellingPrice: '250',
      discount: discount,
      totalPrice: '250',
      category: 'Rings',
      categoryId: '3',
      quantity: '5',
      image: '-',
      sku: sku,
    );

class FakeProductService implements ProductService {
  ApiException? failWith;
  int calls = 0;
  Map<String, dynamic>? lastRequest;
  List<int>? lastImage;

  Future<T> _answer<T>(T value) async {
    calls++;
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<List<ProductModel>> list() => _answer([product('1', 'Silver ring', discount: '20', sku: 'RNG-001'), product('2', 'Gold chain')]);

  @override
  Future<ProductModel> create(Map<String, dynamic> p, {required List<int> image, String? filename}) {
    lastRequest = p;
    lastImage = image;
    return _answer(product('9', p['name'] as String));
  }

  @override
  Future<ProductModel> update(int id, Map<String, dynamic> p, {List<int>? image, String? filename}) {
    lastRequest = p;
    lastImage = image;
    return _answer(product('$id', p['name'] as String));
  }

  @override
  Future<void> delete(int id) => _answer(null);
}

class FakeVariantsService implements ProductVariantsService {
  final created = <String>[];
  ApiException? failAfter;

  @override
  Future<ProductVariant> create(int productId, ProductVariantRequest r) async {
    if (failAfter != null && created.length == 1) throw failAfter!;
    created.add('${r.size}/${r.color}');
    return ProductVariant.fromJson({'id': created.length, 'size': r.size, 'color': r.color, 'quantity': 0});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const validForm = ProductForm(
  name: ' Silver ring ',
  buyingPrice: '100',
  sellingPrice: '250,5',
  discount: '',
  quantity: '7',
  categoryId: 3,
);

void main() {
  late FakeProductService service;
  late FakeVariantsService variants;
  late ProductVM vm;

  setUp(() async {
    service = FakeProductService();
    variants = FakeVariantsService();
    vm = ProductVM(service, variants);
    await vm.fetch();
    service.calls = 0;
  });

  test('search matches name or SKU', () {
    expect(vm.search('rng').map((p) => p.id), ['1']);
    expect(vm.search('CHAIN').map((p) => p.id), ['2']);
  });

  test('unit discounts are keyed by product id', () {
    expect(vm.unitDiscounts, {1: 20, 2: 0});
  });

  test('every invalid field is reported, including the missing image', () async {
    final ok = await vm.add(
      const ProductForm(name: '', buyingPrice: 'abc', sellingPrice: '', quantity: '-1'),
      image: null,
    );

    expect(ok, isFalse);
    expect(vm.fieldError('name'), 'Enter the product name.');
    expect(vm.fieldError('buyingPrice'), 'Buying price must be a number.');
    expect(vm.fieldError('sellingPrice'), 'Enter the selling price.');
    expect(vm.fieldError('quantity'), "Stock can't be negative.");
    expect(vm.fieldError('categoryId'), 'Choose a category.');
    expect(vm.fieldError('image'), 'Choose a product image.');
    expect(service.calls, 0);
  });

  test('discount above the selling price is caught', () async {
    final ok = await vm.add(
      const ProductForm(name: 'x', buyingPrice: '1', sellingPrice: '100', discount: '150', quantity: '1', categoryId: 3),
      image: [1],
    );
    expect(ok, isFalse);
    expect(vm.fieldError('discount'), "Discount can't be more than the selling price.");
  });

  test('add sends typed numbers and puts the product first', () async {
    expect(await vm.add(validForm, image: [1, 2]), isTrue);

    expect(service.lastRequest, {
      'name': 'Silver ring',
      'nameAr': '',
      'description': '',
      'descriptionAr': '',
      'buyingPrice': 100.0,
      'sellingPrice': 250.5,
      'discount': 0,
      'quantity': 7,
      'categoryId': 3,
    });
    expect(vm.allProducts.first.id, '9');
    expect(vm.warning, isNull);
  });

  test('add creates one variant per size × color and says to set their stock', () async {
    expect(await vm.add(validForm, image: [1], sizes: ['S', 'M'], colors: ['Red']), isTrue);

    expect(variants.created, ['S/Red', 'M/Red']);
    expect(vm.warning, contains('Set the stock of each size/color'));
  });

  test('a variant failure keeps the product and explains', () async {
    variants.failAfter = const ApiException(code: 'CONFLICT', message: 'This size/color already exists.');

    expect(await vm.add(validForm, image: [1], sizes: ['S', 'M']), isTrue);
    expect(vm.warning, "Product added, but some sizes/colors weren't saved: This size/color already exists.");
  });

  test('update skips stock checks for products with variants and sends no image unless given', () async {
    final withVariants = product('1', 'Silver ring')
      ..variants = [ProductVariant.fromJson({'id': 1, 'size': 'S', 'quantity': 2})];

    final ok = await vm.update(withVariants,
        const ProductForm(name: 'Silver ring 2', buyingPrice: '1', sellingPrice: '2', quantity: '', categoryId: 3));

    expect(ok, isTrue);
    expect(service.lastImage, isNull);
    expect(vm.allProducts.first.name, 'Silver ring 2');
  });

  test('delete removes the product; a failure keeps it', () async {
    service.failWith = ApiException.network();
    expect(await vm.delete(vm.allProducts.first), isFalse);
    expect(vm.allProducts, hasLength(2));
    expect(vm.deletingId, isNull);

    service.failWith = null;
    expect(await vm.delete(vm.allProducts.first), isTrue);
    expect(vm.allProducts.map((p) => p.id), ['2']);
  });
}
