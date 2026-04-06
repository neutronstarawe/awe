class Constellation {
  final String name;
  final List<List<int>> lines; // each sub-list is [fromHIP, toHIP]

  const Constellation({required this.name, required this.lines});

  factory Constellation.fromJson(String name, List<dynamic> lines) =>
      Constellation(
        name: name,
        lines: lines
            .map((l) => (l as List).map((e) => e as int).toList())
            .toList(),
      );
}
