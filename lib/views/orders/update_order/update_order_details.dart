import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/update_order/updatePaymentDetails.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/update_order_v_m.dart';
import 'package:warsha_app/views/products/add_product.dart';
import 'customer_details.dart';
import 'delivery_address.dart';
import 'order_item_widget.dart';

class UpdateOrderDetails extends StatelessWidget {
  const UpdateOrderDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UpdatePaymentDetails, UpdateOrderVM>(
      builder: (context, payment, order, child) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Row(
                children: [DefaultText(txt: "Order Details")],
              ),
            ),
          ),

          //customer info
          const SliverToBoxAdapter(child: CustomerDetails()),

          const SliverToBoxAdapter(child: SizedBox(height: 15)),

          //delivery
          const SliverToBoxAdapter(child: DeliveryAddress()),

          const SliverToBoxAdapter(child: SizedBox(height: 15)),

          //order item title
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 5),
              child: Row(
                children: [
                  Icon(
                    Iconsax.receipt_item_copy,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  const DefaultText(txt: "Order Items"),
                ],
              ),
            ),
          ),

          // list of order items
          order.orderModel.orderItems.isNotEmpty
              ? SliverFixedExtentList(
                  itemExtent: 60,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: UpdateOrderItem(index, orderItem: Provider.of<UpdateOrderVM>(context).
                          orderModel.orderItems[index]),
                      );
                    },
                    childCount: order.orderModel.orderItems.length,
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.shopping_cart,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        const DefaultText(txt: "Put items in list first!"),
                      ],
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.call_incoming_copy,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text("Order Platform Source", style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Which platform did you get the order from?",
                      prefixIcon: Icon(Iconsax.message, size: 20),
                    ),
                    initialValue: payment.platformSource.text.isNotEmpty
                        ? payment.platformSource.text.toLowerCase()
                        : null,
                    items: const [
                      DropdownMenuItem(value: "facebook", child: Text("Facebook")),
                      DropdownMenuItem(value: "tiktok", child: Text("TikTok")),
                      DropdownMenuItem(value: "instagram", child: Text("Instagram")),
                      DropdownMenuItem(value: "ecommerce", child: Text("E-commerce")),
                      DropdownMenuItem(value: "e-commerce", child: Text("E-commerce")),
                    ],
                    onChanged: (selected) {
                      if (selected != null) {
                        payment.platformSource.text = selected;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 15)),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.wallet_1_copy,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text("Payment Details", style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          controller: payment.downPayment,
                          decoration: const InputDecoration(
                            labelText: "Down Payment",
                            prefixIcon: Icon(Iconsax.wallet_1, size: 20),
                            suffixText: "EGP",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: TextField(
                          controller: payment.delivery,
                          decoration: const InputDecoration(
                            labelText: "Delivery Charge",
                            prefixIcon: Icon(Iconsax.truck, size: 20),
                            suffixText: "EGP",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: payment.discount,
                    decoration: const InputDecoration(
                      labelText: "Discount",
                      prefixIcon: Icon(Iconsax.discount_shape, size: 20),
                      suffixText: "EGP",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Payment Method",
                      prefixIcon: Icon(Iconsax.wallet_1, size: 20),
                    ),
                    initialValue: payment.paymentMethod.text.isNotEmpty
                        ? payment.paymentMethod.text.toLowerCase()
                        : null,
                    items: const [
                      DropdownMenuItem(value: "vodafone cash", child: Text("Vodafone Cash")),
                      DropdownMenuItem(value: "instapay", child: Text("Instapay")),
                      DropdownMenuItem(value: "cash", child: Text("Cash")),
                      DropdownMenuItem(value: "-", child: Text("Other")),
                    ],
                    onChanged: (selected) {
                      if (selected != null) {
                        payment.paymentMethod.text = selected;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: payment.notes,
                    decoration: const InputDecoration(
                      labelText: "Additional notes",
                      prefixIcon: Icon(Iconsax.note, size: 20),
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
