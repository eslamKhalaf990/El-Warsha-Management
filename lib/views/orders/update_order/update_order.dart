import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/update_order/updatePaymentDetails.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/update_order_v_m.dart';
import 'package:warsha_app/views/orders/order_ui.dart';
import 'package:warsha_app/views/orders/update_order/customer_to_update.dart';
import 'package:warsha_app/views/orders/update_order/product_to_update.dart';
import 'package:warsha_app/views/orders/update_order/update_order_details.dart';

class UpdateOrder extends StatefulWidget {
  final OrderModel existingOrder;
  const UpdateOrder({super.key, required this.existingOrder});

  @override
  State<UpdateOrder> createState() => _UpdateOrderState();
}

class _UpdateOrderState extends State<UpdateOrder> {
  final _customerSearch = TextEditingController();
  final _productSearch = TextEditingController();

  @override
  void dispose() {
    _customerSearch.dispose();
    _productSearch.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill once, after the first frame (the VMs notify listeners).
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    context.read<OrderVM>().clearError();
    context.read<UpdatePaymentDetails>().loadPayment(widget.existingOrder);
    final updateVM = context.read<UpdateOrderVM>();
    updateVM.loadOrder(widget.existingOrder);

    // Product discounts aren't in the order response; take them from the
    // catalogue, as the backend does when the order is saved.
    final productVM = context.read<ProductVM>();
    if (!productVM.hasLoaded) await productVM.fetch();
    if (!mounted) return;
    updateVM.applyUnitDiscounts(productVM.unitDiscounts);
  }

  Future<void> _submit(UpdateOrderVM orderVM, UpdatePaymentDetails payment) async {
    final orderId = orderVM.orderModel.orderId;
    if (orderId == null) return;

    // No bankAccountId: the backend keeps the down payment in its original account.
    final form = OrderForm(
      customer: orderVM.orderModel.customer,
      items: orderVM.orderModel.orderItems,
      quantityOf: (item) => item.orderedQuantity,
      paymentMethod: payment.paymentMethod.text,
      orderSource: payment.platformSource.text,
      notes: payment.notes.text,
      downPayment: payment.downPayment.text,
      delivery: payment.delivery.text,
      discount: payment.discount.text,
    );

    final ordersVM = context.read<OrderVM>();
    final updated = await ordersVM.saveOrder(orderId, form);
    if (!mounted) return;

    if (!updated) {
      showOrderError(context, ordersVM.lastError, isShownField: isOrderFormField);
      return;
    }

    showOrderMessage(context, 'Order #$orderId updated');
    refreshAfterOrderChange(context);
    payment.clearPaymentDetails();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final orderVM = context.read<UpdateOrderVM>();
    final payment = context.read<UpdatePaymentDetails>();

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Update Order",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight + 20),
          child: Row(
            children: [
              // Order details panel
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                  child: Card(
                    child: Stack(
                      children: [
                        const UpdateOrderDetails(),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: Provider.of<OrderVM>(context).isSaving
                                        ? null
                                        : () => _submit(orderVM, payment),
                                    child: Provider.of<OrderVM>(context).isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text("Update Order"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Amount Due",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        "${Provider.of<UpdatePaymentDetails>(context).totalsFor(Provider.of<UpdateOrderVM>(context).orderModel.orderItems).amountDue.toStringAsFixed(2)} EGP",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Products panel
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Products",
                                style: Theme.of(context).textTheme.titleMedium,
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _productSearch,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or SKU',
                              prefixIcon: Icon(Icons.search, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: ProductToUpdate(query: _productSearch.text)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Customers panel
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Customers",
                                style: Theme.of(context).textTheme.titleMedium,
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _customerSearch,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or phone',
                              prefixIcon: Icon(Icons.search, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: CustomerToUpdate(query: _customerSearch.text)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
