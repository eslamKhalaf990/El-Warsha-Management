import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/app_text_field.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

/// Add a shipping zone, or edit [zone] when given.
class AddShippingZone extends StatefulWidget {
  const AddShippingZone({super.key, this.zone});

  final ShippingZone? zone;

  @override
  State<AddShippingZone> createState() => _AddShippingZoneState();
}

class _AddShippingZoneState extends State<AddShippingZone> {
  late final _cityController = TextEditingController(text: widget.zone?.cityName);
  late final _priceController = TextEditingController(
    text: widget.zone == null ? '' : widget.zone!.priceLabel.replaceAll(' EGP', ''),
  );
  late bool _isActive = widget.zone?.isActive ?? true;

  bool get _isEdit => widget.zone != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShippingZoneVM>().clearError();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<ShippingZoneVM>();
    final ok = await vm.save(
      cityName: _cityController.text,
      priceText: _priceController.text,
      isActive: _isActive,
      editingId: widget.zone?.id,
    );
    if (!mounted) return;
    reportResult(
      context,
      ok: ok,
      errorMessage: vm.errorMessage,
      success: _isEdit ? 'Shipping zone updated.' : 'Shipping zone added.',
      fieldError: vm.fieldError,
      fields: const ['cityName', 'shippingFee'],
      pop: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoneVM = context.watch<ShippingZoneVM>();

    return Scaffold(
      appBar: AppBar(
        title: DefaultText(txt: _isEdit ? "Edit Shipping Zone" : "Add New Shipping Zone", bold: true, size: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Zone Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 25),
              AppTextField(
                label: "Governorate *",
                controller: _cityController,
                icon: Iconsax.location_copy,
                textDirection: TextDirection.rtl,
                maxLength: ShippingZoneVM.nameMaxLength,
                errorText: zoneVM.fieldError('cityName'),
                onChanged: (_) => zoneVM.clearError(),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: "Delivery price (EGP) *",
                controller: _priceController,
                icon: Iconsax.money_send_copy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                errorText: zoneVM.fieldError('shippingFee'),
                onChanged: (_) => zoneVM.clearError(),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text("Delivering here"),
                subtitle: const Text("When off, the store hides this governorate and customers there can't check out."),
              ),
              const SizedBox(height: 30),
              FormActions(onSave: _save, saving: zoneVM.isSaving, saveLabel: _isEdit ? "Save Changes" : "Save Zone"),
            ],
          ),
        ),
      ),
    );
  }
}
