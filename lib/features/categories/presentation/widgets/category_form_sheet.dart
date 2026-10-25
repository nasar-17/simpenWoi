import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../home/presentation/widgets/transaction_type_selector.dart';
import '../providers/category_providers.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.category, this.initialType});

  final Category? category;
  final String? initialType;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _keywordsController;
  late String _type;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final Category? category = widget.category;
    _nameController = TextEditingController(text: category?.name);
    _keywordsController = TextEditingController(text: category?.keywords);
    _type = category?.type ?? widget.initialType ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Nama kategori wajib diisi.');
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final String keywords = _keywordsController.text;
      final Category? category = widget.category;
      if (category == null) {
        await ref
            .read(categoryServiceProvider)
            .add(name: name, type: _type, keywords: keywords);
      } else {
        await ref
            .read(categoryServiceProvider)
            .update(id: category.id, name: name, keywords: keywords);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        _showMessage(error.toString());
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _isEdit ? 'Ubah kategori' : 'Tambah kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                labelText: 'Kata kunci (opsional)',
                helperText: 'Pisahkan dengan koma, contoh: kopi, cafe',
              ),
            ),
            const SizedBox(height: 12),
            if (_isEdit)
              Text(
                'Jenis: ${_type == TransactionType.income ? UiText.income : UiText.expense}',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              TransactionTypeSelector(
                type: _type,
                onChanged: (String type) {
                  setState(() {
                    _type = type;
                  });
                },
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text(UiText.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text(UiText.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
