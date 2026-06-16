class JournalEntry {
  final int? id;
  final String body;
  final DateTime createdAt;

  const JournalEntry({
    this.id,
    required this.body,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'body': body,
        'created_at': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map<String, dynamic> m) => JournalEntry(
        id: m['id'] as int,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  JournalEntry copyWith({String? body}) => JournalEntry(
        id: id,
        body: body ?? this.body,
        createdAt: createdAt,
      );
}
