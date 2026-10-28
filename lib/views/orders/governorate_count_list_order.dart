import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/view_models/add_order_v_m.dart';

class GovernorateCountList extends StatelessWidget {
  const GovernorateCountList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AddOrderVM>();
          if (!vm.hasLoaded) {
            return const SizedBox.shrink();
          } else {
            final governorateCounts = vm.governorateCounts;
            if (governorateCounts.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: governorateCounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = governorateCounts[index];
                  final colorScheme = Theme.of(context).colorScheme;
                  return Container(
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.tertiary.withAlpha(50),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Governorate name
                          Text(
                            item.governorate,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Divider line
                          Container(
                            height: 3,
                            width: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.tertiary.withAlpha(50),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Orders count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.count}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                  color: colorScheme.tertiary.withAlpha(200),

                                ),
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 3.0),
                                child: Text(
                                  'Orders',
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}