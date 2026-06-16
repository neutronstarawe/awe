import 'package:flutter/material.dart';
import '../core/journal_service.dart';
import '../models/journal_entry.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? existing;

  const JournalEntryScreen({super.key, this.existing});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final svc = JournalService();
    if (widget.existing == null) {
      await svc.insert(text);
    } else {
      await svc.update(widget.existing!.copyWith(body: text));
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Delete this entry?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w300,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w300)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w300)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await JournalService().delete(widget.existing!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.existing == null ? 'New Entry' : 'Edit Entry',
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.white.withValues(alpha: 0.35), size: 20),
              onPressed: _saving ? null : _confirmDelete,
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white.withValues(alpha: _saving ? 0.3 : 0.7),
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 15,
            fontWeight: FontWeight.w300,
            height: 1.7,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'What are you feeling right now…',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
          ),
          cursorColor: Colors.white38,
        ),
      ),
    );
  }
}
