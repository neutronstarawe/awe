import 'package:flutter/material.dart';
import '../core/journal_service.dart';
import '../models/journal_entry.dart';
import 'journal_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _svc = JournalService();
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _svc.all();
    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _openEntry([JournalEntry? entry]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(existing: entry),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(JournalEntry entry) async {
    await _svc.delete(entry.id!);
    _load();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Journal',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white54),
            onPressed: () => _openEntry(),
          ),
        ],
      ),
      body: _loading
          ? const SizedBox.shrink()
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    'No entries yet.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withValues(alpha: 0.06),
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.withValues(alpha: 0.15),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                      ),
                      onDismissed: (_) => _delete(e),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        onTap: () => _openEntry(e),
                        title: Text(
                          e.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            height: 1.5,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDate(e.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
