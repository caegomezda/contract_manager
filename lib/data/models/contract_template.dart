class ContractTemplate {
  String id;
  String title;
  String body; // Aquí es donde irán las {{hotkeys}}
  DateTime lastModified;

  ContractTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.lastModified,
  });
}