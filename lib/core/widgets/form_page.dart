import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/core/widgets/app_button.dart';
import 'package:warsha_app/core/widgets/app_card.dart';
import 'package:warsha_app/core/widgets/app_text.dart';
import 'package:warsha_app/core/widgets/feedback.dart';
import 'package:warsha_app/core/widgets/status_pill.dart';

/// Pushes a full-page form with its own [FormDraft] (disposed with the page).
Future<T?> pushFormPage<T>(BuildContext context, {required FormDraft Function() draft, required Widget page}) =>
    Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => draft(), child: page)),
    );

/// Shows a dialog form with its own [FormDraft].
Future<T?> showFormDialog<T>(BuildContext context, {required FormDraft Function() draft, required Widget dialog}) =>
    showDialog<T>(
      context: context,
      builder: (_) => ChangeNotifierProvider(create: (_) => draft(), child: dialog),
    );

/// Full-page add/edit form: back button and title on top, the sections in a
/// centered column (two columns of sections on wide screens when [aside] is
/// given), and Cancel / Save pinned to the bottom.
///
/// Ctrl/⌘+S saves. Leaving with unsaved changes in [draft] asks first.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.sections,
    required this.onSave,
    required this.saving,
    required this.saveLabel,
    this.subtitle,
    this.aside = const [],
    this.draft,
    this.headerActions = const [],
  });

  final String title;
  final String? subtitle;

  /// The main column of [FormSection]s.
  final List<Widget> sections;

  /// Sections shown in a narrower right column on wide screens (summary,
  /// image...), and after [sections] on narrow ones.
  final List<Widget> aside;
  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;
  final FormDraft? draft;
  final List<Widget> headerActions;

  @override
  Widget build(BuildContext context) {
    final wide = context.isExpanded && aside.isNotEmpty;
    final padding = context.pagePadding;

    Widget column(List<Widget> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s16),
              items[i],
            ],
          ],
        );

    final body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: column(sections)),
              const SizedBox(width: AppSpacing.s24),
              Expanded(flex: 2, child: column(aside)),
            ],
          )
        : column([...sections, ...aside]);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => saving ? null : onSave(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => saving ? null : onSave(),
      },
      child: PopScope(
        canPop: draft == null,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final leave = !draft!.isDirty ||
              await confirmAction(
                context,
                title: 'Discard changes?',
                message: "You have changes that aren't saved yet.",
                confirmLabel: 'Discard',
                icon: Iconsax.warning_2_copy,
              );
          if (leave && context.mounted) Navigator.pop(context);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left_copy),
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null) AppText.caption(subtitle!),
              ],
            ),
            actions: [...headerActions, SizedBox(width: padding - AppSpacing.s8)],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.s8, padding, AppSpacing.s32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? Breakpoints.contentMaxWidth : Breakpoints.formMaxWidth),
                  child: FocusTraversalGroup(child: body),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _ActionBar(onSave: onSave, saving: saving, saveLabel: saveLabel),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onSave, required this.saving, required this.saveLabel});

  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: AppSpacing.s12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!compact) ...[
                const AppText.caption('Ctrl + S to save'),
                const Spacer(),
              ],
              AppButton.secondary(label: 'Cancel', onPressed: () => Navigator.maybePop(context)),
              const SizedBox(width: AppSpacing.s12),
              compact
                  ? Expanded(
                      child: AppButton.primary(label: saveLabel, onPressed: onSave, loading: saving, icon: Iconsax.tick_circle_copy),
                    )
                  : AppButton.primary(label: saveLabel, onPressed: onSave, loading: saving, icon: Iconsax.tick_circle_copy),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled card that groups related fields; children are spaced evenly.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[IconBadge(icon!, size: 36), const SizedBox(width: AppSpacing.s12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(title),
                    if (subtitle != null) AppText.caption(subtitle!),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Puts fields side by side when there is room (≥ 520px), stacked otherwise.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children, this.flex});

  final List<Widget> children;

  /// Relative widths when side by side; equal by default.
  final List<int>? flex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s16),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s16),
              Expanded(flex: flex?[i] ?? 1, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
