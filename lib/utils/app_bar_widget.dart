import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DefaultAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.logout),
          tooltip: 'Log out',
          onPressed: () => context.read<UserViewModel>().logout(),
        ),
      ],
      title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                  borderRadius: Constants.BORDER_RADIUS_100,
                  child: Image.asset("assets/images/logo-no-back.png", width: 40,),
              ),
              const SizedBox(width: 10,),
              const DefaultText(
                txt: "ELWARSHA",
                bold: true,
              ),
            ],
          ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
