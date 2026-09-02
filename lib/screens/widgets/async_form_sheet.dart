import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class AsyncFormSheet extends StatefulWidget {
  const AsyncFormSheet(
      {super.key,
      required this.title,
      required this.submitLabel,
      required this.fields,
      required this.onSubmit});

  final String title;
  final String submitLabel;
  final Widget Function(BuildContext, bool, VoidCallback) fields;
  final Future<void> Function() onSubmit;

  @override
  State<AsyncFormSheet> createState() => _AsyncFormSheetState();
}

class _AsyncFormSheetState extends State<AsyncFormSheet> {
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is ApiException
              ? error.message
              : 'Não foi possível salvar. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
            child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    widget.fields(context, _busy, () {
                      if (mounted) setState(() {});
                    }),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Text(widget.submitLabel),
                    ),
                  ],
                )),
          ),
        ),
      );
}

Future<bool> confirmDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: const Text('Esta exclusão não pode ser desfeita.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir')),
              ],
            )) ??
    false;

void showActionError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
    error is ApiException
        ? error.message
        : 'Não foi possível concluir a operação. Tente novamente.',
  )));
}

String timeValue(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
