import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
//
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/view_models/update_order_v_m.dart';

class UpdateOrderItem extends StatelessWidget {
  final int index;
  final OrderItemModel orderItem;
  const UpdateOrderItem(this.index, {super.key, required this.orderItem});

  @override
  Widget build(BuildContext context) {
    final order = orderItem;
    final quantityError = context.watch<OrderVM>().fieldError('items[$index].quantity');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              order.productName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          Row(
            children: [
              IconButton(
                onPressed: (){
                  Provider.of<UpdateOrderVM>(context,listen: false).incrementItemQuantity = index;
                },
                icon: const Icon(Iconsax.add_square, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: quantityError == null
                    ? Text(
                        order.orderedQuantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : Tooltip(
                        message: quantityError,
                        child: Text(
                          order.orderedQuantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
              ),
              IconButton(
                onPressed: (){
                  Provider.of<UpdateOrderVM>(context,listen: false).decrementItemQuantity = index;
                },
                icon: const Icon(Iconsax.minus_square, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16,),
              Text(
                "${order.unitPrice * (order.orderedQuantity)} EGP",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}