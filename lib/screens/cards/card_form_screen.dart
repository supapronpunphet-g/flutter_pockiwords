import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/flashcard.dart';
import '../../providers/card_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/pocki_button.dart';
import '../../widgets/pocki_text_field.dart';

class CardFormScreen extends StatefulWidget {
  const CardFormScreen({super.key, this.card});

  final Flashcard? card;
  bool get isEditing => card != null;

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _front =
      TextEditingController(text: widget.card?.frontWord ?? '');
  late final TextEditingController _back =
      TextEditingController(text: widget.card?.backTranslation ?? '');
  late final TextEditingController _example =
      TextEditingController(text: widget.card?.exampleSentence ?? '');
  late CardDifficulty _difficulty =
      widget.card?.difficulty ?? CardDifficulty.medium;
  bool _saving = false;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _example.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CardProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = widget.isEditing
        ? await provider.updateCard(
            cardId: widget.card!.id,
            frontWord: _front.text,
            backTranslation: _back.text,
            exampleSentence: _example.text,
            difficulty: _difficulty,
          )
        : await provider.createCard(
            frontWord: _front.text,
            backTranslation: _back.text,
            exampleSentence: _example.text,
            difficulty: _difficulty,
          );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isEditing ? 'Card updated' : 'Card added 🎉'),
      ));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Could not save card'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Card' : 'New Card'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                PockiTextField(
                  controller: _front,
                  label: 'Front (English word)',
                  hint: 'e.g. Hello',
                  icon: Icons.translate_rounded,
                  validator: (v) => Validators.notEmpty(v, field: 'Front word'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                PockiTextField(
                  controller: _back,
                  label: 'Back (Thai meaning)',
                  hint: 'e.g. สวัสดี',
                  icon: Icons.subtitles_rounded,
                  validator: (v) =>
                      Validators.notEmpty(v, field: 'Translation'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                PockiTextField(
                  controller: _example,
                  label: 'Example sentence (optional)',
                  hint: 'e.g. Hello, how are you?',
                  icon: Icons.format_quote_rounded,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Difficulty',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: CardDifficulty.values.map((d) {
                    final selected = _difficulty == d;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _difficulty = d),
                      selectedColor: d.color.withValues(alpha: 0.25),
                      side: BorderSide(
                        color: selected
                            ? d.color
                            : AppColors.secondary.withValues(alpha: 0.6),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? d.color : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: AppColors.surface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PockiButton(
                  label: widget.isEditing ? 'Save Changes' : 'Add Card',
                  icon: widget.isEditing
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
