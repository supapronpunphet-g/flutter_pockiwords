import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/pocki_button.dart';
import '../../widgets/pocki_text_field.dart';

class DeckFormScreen extends StatefulWidget {
  const DeckFormScreen({super.key, this.deck});

  /// Pass an existing deck to edit. Null means create.
  final Deck? deck;

  bool get isEditing => deck != null;

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.deck?.title ?? '');
  late final TextEditingController _language =
      TextEditingController(text: widget.deck?.language ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.deck?.description ?? '');

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<DeckProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = widget.isEditing
        ? await provider.updateDeck(
            deckId: widget.deck!.id,
            title: _title.text,
            language: _language.text,
            description: _description.text,
          )
        : await provider.createDeck(
            title: _title.text,
            language: _language.text,
            description: _description.text,
          );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isEditing ? 'Deck updated' : 'Deck created 🎉'),
      ));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Could not save deck'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Deck' : 'New Deck'),
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
                  controller: _title,
                  label: 'Title',
                  hint: 'e.g. Korean Basics',
                  icon: Icons.collections_bookmark_rounded,
                  validator: (v) => Validators.notEmpty(v, field: 'Title'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                PockiTextField(
                  controller: _language,
                  label: 'Language',
                  hint: 'e.g. Korean, French, Spanish…',
                  icon: Icons.translate_rounded,
                  validator: (v) => Validators.notEmpty(v, field: 'Language'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                PockiTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  hint: 'What is this deck about?',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppSpacing.xl),
                PockiButton(
                  label: widget.isEditing ? 'Save Changes' : 'Create Deck',
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
