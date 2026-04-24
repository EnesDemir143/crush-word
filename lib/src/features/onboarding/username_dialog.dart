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
    final ThemeData theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFFFCF7), Color(0xFFF6EFE2)],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x1A1A5D57),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF1A5D57),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3A3025),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu isim ana menude ve oyun icinde gorunecek.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F6252),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: 'Oyuncu adi',
                      hintText: 'Adini yaz ve devam et',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.86),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCCAA8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCCAA8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A5D57),
                          width: 1.6,
                        ),
                      ),
                      counterStyle: const TextStyle(
                        color: Color(0xFF7A6F62),
                        fontSize: 11,
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (String? value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'Devam etmek icin bir kullanici adi gir.';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    if (widget.allowCancel)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6F6252),
                            side: const BorderSide(color: Color(0xFFDCCAA8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Vazgec'),
                        ),
                      ),
                    if (widget.allowCancel) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5D57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(widget.confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
