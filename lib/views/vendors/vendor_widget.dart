import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';
import 'package:warsha_app/views/vendors/add_vendor.dart';

class VendorWidget extends StatelessWidget {
  final Vendor vendor;

  const VendorWidget({
    super.key,
    required this.vendor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 700;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVendorAvatar(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    txt: vendor.name,
                    size: 16,
                    bold: true,
                  ),
                  const SizedBox(height: 4),
                  DefaultText(
                    txt: "Contact: ${vendor.contactPerson ?? 'N/A'}",
                    size: 13,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _buildEditButton(context, compact: true),
                _buildDeleteButton(context, compact: true),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoChips(context),
      ],
    );
  }

  // ==========================================
  // DESKTOP LAYOUT
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildVendorAvatar(context),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultText(txt: vendor.name, size: 18, bold: true),
              const SizedBox(height: 4),
              DefaultText(
                txt: "Tax ID: ${vendor.taxNumber ?? 'No Tax ID'}",
                size: 13,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildInfoChips(context),
        ),
        const SizedBox(width: 20),
        Container(width: 1, height: 50, color: Colors.grey.shade200),
        const SizedBox(width: 20),
        Row(
          children: [
            _buildEditButton(context, compact: false),
            const SizedBox(width: 8),
            _buildDeleteButton(context, compact: false),
          ],
        )
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildVendorAvatar(BuildContext context) {
    String initials = vendor.name.isNotEmpty ? vendor.name.substring(0, 1).toUpperCase() : "V";

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          initials,
          style:  TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(vendor.phone ?? "No Phone", Iconsax.call, Colors.grey.shade100, Colors.black87),
        _buildChip(vendor.address ?? "No Address", Iconsax.location, Colors.grey.shade100, Colors.black87),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textCol),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textCol),
            ),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddVendor(vendor: vendor)));
  }

  Widget _buildEditButton(BuildContext context, {required bool compact}) {
    if (compact) {
      return IconButton(
        tooltip: "Edit",
        onPressed: () => _openEdit(context),
        icon: const Icon(Iconsax.edit, color: Colors.black87, size: 20),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _openEdit(context),
      icon: const Icon(Iconsax.edit, size: 16),
      label: const Text("Edit"),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, {required bool compact}) {
    final vendorVM = context.read<VendorVM>();

    return IconButton(
      tooltip: "Archive",
      onPressed: () async {
        final confirm = await _showDeleteDialog(context);
        if (confirm != true || !context.mounted) return;
        final ok = await vendorVM.archive(vendor);
        if (!context.mounted) return;
        if (ok) {
          showSuccess(context, '"${vendor.name}" archived.');
        } else {
          showError(context, vendorVM.errorMessage!);
        }
      },
      icon: Icon(Iconsax.trash, color: Colors.red.shade400, size: compact ? 20 : 24),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Archive Vendor"),
        content: Text("Archive ${vendor.name}? It will be hidden from this list, but its record is kept."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Archive", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}