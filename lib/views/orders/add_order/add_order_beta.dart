import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/order_request.dart';

// Models & Values
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/utils/navigator.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';

// View Models
import 'package:warsha_app/view_models/add_order_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/controllers/add_order/add_payment.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

class AddOrderBeta extends StatelessWidget {
  const AddOrderBeta({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: isDesktop
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  // --- Mobile Layout (Single Column) ---
  Widget _buildMobileLayout(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 40), // Space for scrolling
      child: Column(
        children: [
          CustomerSelectionSection(),
          SizedBox(height: 20),
          OrderLineItemsSection(),
          SizedBox(height: 20),
          OrderSummaryCard(), // Summary at bottom of scroll to avoid keyboard overlap
        ],
      ),
    );
  }

  // --- Desktop Layout (Row) ---
  Widget _buildDesktopLayout(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomerSelectionSection(),
                SizedBox(height: 24),
                OrderLineItemsSection(),
              ],
            ),
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(child: OrderSummaryCard()),
        ),
      ],
    );
  }
}

// --- REUSABLE DECORATION STYLE ---
InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18, color: Colors.grey),
    filled: true,
    fillColor: Colors.grey.shade50,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
    ),
  );
}

class CustomerSelectionSection extends StatelessWidget {
  const CustomerSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.user_tag, color: Theme.of(context).colorScheme.tertiary, size: 22),
                const SizedBox(width: 10),
                const DefaultText(txt: "Customer Info", bold: true, size: 16),
              ],
            ),
          const SizedBox(height: 20),

          Consumer<CustomerVM>(
            builder: (context, customerVM, _) {
              if (customerVM.allCustomers == null) {
                return const LinearProgressIndicator();
              }

              return FutureBuilder(
                future: customerVM.allCustomers,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  return SearchAnchor(
                    viewElevation: 2,
                    builder: (BuildContext context, SearchController controller) {
                      return SearchBar(
                        elevation: const WidgetStatePropertyAll<double>(0.0),
                        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                                side: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1)

                            ),
                        ),
                        controller: controller,
                        padding: const WidgetStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(horizontal: 16.0)),
                        onTap: () => controller.openView(),
                        onChanged: (_) => controller.openView(),
                        leading: const Icon(Iconsax.profile_circle),
                        hintText: "Search Customer...",
                      );
                    },
                    suggestionsBuilder: (BuildContext context, SearchController controller) {
                      final String input = controller.value.text.toLowerCase();

                      // snapshot.data is your List<CustomerModel>
                      return snapshot.data!
                          .where((customer) =>
                          customer.fullName.toLowerCase().contains(input) ||
                          customer.phone.contains(input))
                          .take(15) // Performance: Limit suggestions
                          .map((customer) => ListTile(
                        title: Text(customer.fullName),
                        subtitle: Text(customer.phone),
                        onTap: () {
                          controller.closeView(customer.fullName);
                          Provider.of<AddOrderVM>(context, listen: false)
                              .addCustomer = customer;
                        },
                      ));
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // ADDRESS DISPLAY
          Consumer<AddOrderVM>(
            builder: (context, vm, _) {
              if (vm.orderModel.customer == null) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withAlpha(20),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Theme.of(context).colorScheme.tertiary),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.location, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Delivery Address",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.tertiary)),
                          const SizedBox(height: 4),
                          Text(
                            "${vm.orderModel.customer!.address}, ${vm.orderModel.customer!.governorate}",
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ));
  }
}

class OrderLineItemsSection extends StatefulWidget {
  const OrderLineItemsSection({super.key});

  @override
  State<OrderLineItemsSection> createState() => _OrderLineItemsSectionState();
}

class _OrderLineItemsSectionState extends State<OrderLineItemsSection> {
  ProductModel? selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.box, color: Theme.of(context).colorScheme.tertiary, size: 22),
                const SizedBox(width: 10),
                const DefaultText(txt: "Order Items", bold: true, size: 16),
              ],
            ),
          const SizedBox(height: 20),

          // --- ADD ITEM ROW ---
          // Using Wrap or Layout logic to handle very small screens inside the card
          Column(
            children: [
              Consumer<ProductVM>(
                builder: (context, productVM, _) {
                  return FutureBuilder<List<ProductModel>>(
                    future: productVM.allProducts,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      return SearchAnchor(
                        viewElevation: 0, // Removes shadow from the expanded list
                        viewHintText: "Type product name...",
                        viewShape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        builder: (BuildContext context, SearchController controller) {
                          // Set initial text if a product is already selected
                          if (selectedProduct != null && controller.text.isEmpty) {
                            controller.text = selectedProduct!.name;
                          }

                          return SearchBar(
                            controller: controller,
                            elevation: const WidgetStatePropertyAll(0), // Low elevation
                            backgroundColor: WidgetStatePropertyAll(Colors.grey.shade50),
                            shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                                  side: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1)

                              ),
                            ),
                            padding: const WidgetStatePropertyAll<EdgeInsets>(
                                EdgeInsets.symmetric(horizontal: 16.0)),
                            onTap: () => controller.openView(),
                            onChanged: (_) => controller.openView(),
                            leading: const Icon(Iconsax.box_1),
                            hintText: "Select Product",
                          );
                        },
                        suggestionsBuilder: (BuildContext context, SearchController controller) {
                          final String input = controller.value.text.toLowerCase();

                          return snapshot.data!
                              .where((prod) => prod.name.toLowerCase().contains(input))
                              .take(15) // Performance: Limit suggestions
                              .map((prod) => ListTile(
                            title: Text(prod.name),
                            onTap: () {
                              setState(() {
                                selectedProduct = prod;
                                controller.closeView(prod.name);
                              });
                            },
                          ));
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Qty", Iconsax.hashtag),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          backgroundColor:
                              Theme.of(context).colorScheme.tertiary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (selectedProduct != null) {
                            // print(_qtyController.text);
                            final vm =
                                Provider.of<AddOrderVM>(context, listen: false);
                            OrderItemModel item = OrderItemModel(
                              productId: int.parse(selectedProduct!.id),
                              quantity: int.tryParse(_qtyController.text) ?? 1,
                              unitPrice:
                                  double.parse(selectedProduct!.sellingPrice),
                              productName: selectedProduct!.name,
                            );
                            item.quantityToOrder = int.parse(_qtyController.text);
                            vm.addToOrderItems = item;
                            setState(() {
                              selectedProduct = null;
                              _qtyController.text = "1";
                            });
                          }
                        },
                        icon: const Icon(Iconsax.add_circle),
                        label: const Text("Add Item"),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),
          Divider(
            color: Theme.of(context).colorScheme.tertiary.withAlpha(50),
          ),

          // --- ADDED ITEMS LIST ---
          Consumer<AddOrderVM>(
            builder: (context, vm, _) {
              if (vm.orderModel.orderItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        Icon(Iconsax.box_1_copy,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text("Add Your First Item",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: vm.orderModel.orderItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Iconsax.box, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                  "${item.unitPrice} EGP × ${item.quantityToOrder}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          "${item.unitPrice * item.quantityToOrder} EGP",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                          onPressed: () {
                            vm.removeFromOrderItems = item.productId;
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    ));
  }
}

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final payment = Provider.of<PaymentProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
             Row(
              children: [
                Icon(Iconsax.wallet_2, color: Theme.of(context).colorScheme.tertiary, size: 22),
                const SizedBox(width: 10),
                const DefaultText(txt: "Payment", bold: true, size: 16),
              ],
            ),
          const SizedBox(height: 20),

          // 1. Platform Source
          DropdownButtonFormField<String>(
            decoration: _inputDecoration("Source", Iconsax.global),
            initialValue: payment.platformSource.text.isNotEmpty
                ? payment.platformSource.text
                : null,
            items: const [
              DropdownMenuItem(
                  value: "facebook", child: Text("Facebook")),
              DropdownMenuItem(value: "tiktok", child: Text("TikTok")),
              DropdownMenuItem(
                  value: "instagram", child: Text("Instagram")),
              DropdownMenuItem(
                  value: "ecommerce", child: Text("E-commerce")),
            ],
            onChanged: (val) => payment.platformSource.text = val ?? "",
          ),
          const SizedBox(height: 10),

          // 2. Payment Method
          DropdownButtonFormField<String>(
            decoration: _inputDecoration("Method", Iconsax.card),
            initialValue: payment.paymentMethod.text.isNotEmpty
                ? payment.paymentMethod.text
                : null,
            items: const [
              DropdownMenuItem(
                  value: "vodafone cash",
                  child: Text("Vodafone Cash")),
              DropdownMenuItem(
                  value: "instapay", child: Text("Instapay")),
              DropdownMenuItem(value: "cash", child: Text("Cash")),
            ],
            onChanged: (val) => payment.paymentMethod.text = val ?? "",
          ),
          const SizedBox(height: 10),

          // 3. Financials
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: payment.delivery,
                  decoration: _inputDecoration("Delivery", Iconsax.truck),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: payment.discount,
                  decoration:
                      _inputDecoration("Discount", Iconsax.discount_shape),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: payment.downPayment,
            decoration: _inputDecoration("Down Payment", Iconsax.moneys),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 10),
          TextField(
            controller: payment.notes,
            maxLines: 2,
            decoration: _inputDecoration("Notes", Iconsax.note_1),
            keyboardType: TextInputType.text,
          ),

          const SizedBox(height: 25),

          Divider(
            color: Theme.of(context).colorScheme.tertiary.withAlpha(50),
          ),

          // 4. TOTAL
          Consumer<AddOrderVM>(builder: (context, orderVM, _) {
            double productsTotal = orderVM.getTotalPrice();
            double delivery = double.tryParse(payment.delivery.text) ?? 0;
            double discount = double.tryParse(payment.discount.text) ?? 0;
            double downPayment = double.tryParse(payment.downPayment.text) ?? 0;
            double grandTotal = productsTotal + delivery - discount - downPayment;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withAlpha(25),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Grand Total",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    "$grandTotal EGP",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 25),

          // 5. SUBMIT BUTTON
          SizedBox(
            width: double.infinity,
            height: 55,
            child: DefaultButton(
              title: "Save Order",
              onTap: () {
                _submitOrder(context);
              },
              margin: EdgeInsets.zero,
              isValid: !Provider.of<OrderVM>(context).isSaving,
              isLoading: Provider.of<OrderVM>(context).isSaving,
              border: 15,
            ),
          )
        ],
      ),
    ));
  }

  Future<void> _submitOrder(BuildContext context) async {
    final addOrderVM = Provider.of<AddOrderVM>(context, listen: false);
    final payment = Provider.of<PaymentProvider>(context, listen: false);
    final orderVM = Provider.of<OrderVM>(context, listen: false);

    // --- VALIDATION STEP ---

    // Check Customer
    if (addOrderVM.orderModel.customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer first'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Check Items (Logic Fix: Don't allow empty orders)
    if (addOrderVM.orderModel.orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one product'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // --- PREPARATION STEP ---

    // Safe Parsing (Logic Fix: Prevent crash if text is empty)
    final double deliveryCost = double.tryParse(payment.delivery.text) ?? 0.0;
    final double discountAmount = double.tryParse(payment.discount.text) ?? 0.0;
    final double downPaymentAmount =
        double.tryParse(payment.downPayment.text) ?? 0.0;

    int? bankAccountId;

    // Logic Fix: Only ask for Bank Account if there is a down payment
    if (downPaymentAmount > 0) {
      final bankAccount = await showTransferDialog(context, downPaymentAmount);

      if (bankAccount == null) {
        // User cancelled the dialog, so we stop the save process
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Bank account selection is required for down payments'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }
      bankAccountId = bankAccount.id;
    }

    try {
      // Map Items
      final List<OrderLineRequest> itemsToCreate =
          addOrderVM.orderModel.orderItems.map((item) {
        return OrderLineRequest(
          productId: item.productId,
          quantity: item.quantityToOrder,
          unitPrice: item.unitPrice,
        );
      }).toList();

      // Build Request
      final OrderRequest request = OrderRequest(
        customerId: addOrderVM.orderModel.customer!.customerId,
        delivery: deliveryCost,
        discount: discountAmount,
        downPayment: downPaymentAmount,
        notes: payment.notes.text,
        orderSource: payment.platformSource.text,
        paymentMethod: payment.paymentMethod.text,
        items: itemsToCreate,
        bankAccountId: bankAccountId,
      );

      final bool success = await orderVM.addOrder(request);

      if (!context.mounted) return;

      if (success) {
        Provider.of<ProductVM>(context, listen: false).initAllProducts();
        Provider.of<AccountingVM>(context, listen: false).initAccounting();

        // Clear Forms
        payment.clearPaymentDetails();
        addOrderVM.clearOrder();

        // Navigation (Pop twice as per your logic)
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ${orderVM.errorMessage}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<BankAccount?> showTransferDialog(
      BuildContext context, double totalPrice) async {
    BankAccount? selectedAccount;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Completion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                  children: [
                    const TextSpan(
                        text: 'Once the order is completed, the payment ',
                        style: TextStyle(fontSize: 16)),
                    TextSpan(
                      text: '$totalPrice EGP',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const TextSpan(
                        text: ' will be transferred.\n\n',
                        style: TextStyle(fontSize: 16)),
                    const TextSpan(
                        text: 'Select the account to transfer your money to:'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Consumer<AccountingVM>(
                builder: (context, accounting, child) => accounting
                            .accountsBalance ==
                        null
                    ? Container()
                    : DropdownButtonFormField<BankAccount>(
                        initialValue: selectedAccount,
                        hint: const Text('Choose account'),
                        items: accounting.accountsBalance!
                            .map((account) => DropdownMenuItem<BankAccount>(
                                  value: account,
                                  child: Text(account.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedAccount = value),
                        borderRadius: Constants.BORDER_RADIUS_20,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          labelStyle:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                              ),
                              borderRadius: Constants.BORDER_RADIUS_15),
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Icon(
                              Iconsax.bank_copy,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.grey.shade500),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedAccount == null
                  ? null
                  : () => Navigator.pop(context, true),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                backgroundColor:
                    WidgetStateProperty.all<Color>(Colors.green.shade400),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedAccount != null) {
      return selectedAccount;
    }
    return null;
  }
}
