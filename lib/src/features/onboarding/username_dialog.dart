import 'package:flutter/material.dart';

Future<String?> showUsernameDialog({
  required BuildContext context,
  String? initialUsername,
  String title = 'Kullanıcı Adı',
  String confirmLabel = 'Kaydet',
  bool allowCancel = true,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: allowCancel,
    builder: (_) => UsernameDialog(
      initialUsername: initialUsername,
      title: title,
      confirmLabel: confirmLabel,
      allowCancel: allowCancel,
    ),
  );
}

class UsernameDialog extends StatefulWidget {
  const UsernameDialog({
    super.key,
    this.initialUsername,
    required this.title,
    required this.confirmLabel,
    required this.allowCancel,
  });

  final String? initialUsername;
  final String title;
  final String confirmLabel;
  final bool allowCancel;

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialUsername,
  );
  late final FocusNode _focusNode = FocusNode();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _submitted = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.done,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: 'Oyuncu adı',
            hintText: 'Adını yaz ve devam et',
          ),
          onFieldSubmitted: (_) => _submit(),
          validator: (String? value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Devam etmek için bir kullanıcı adı gir.';
            }

            return null;
          },
        ),
      ),
      actions: [
        if (widget.allowCancel)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
