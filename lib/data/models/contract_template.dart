import 'package:cloud_firestore/cloud_firestore.dart';

class ContractTemplate {
  String id;
  String title;
  String body; // Contiene las variables {{nombre}}, {{id}}, etc.
  DateTime lastModified;

  ContractTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.lastModified,
  });

  // Convierte un documento de Firestore a un objeto ContractTemplate
  factory ContractTemplate.fromMap(Map<String, dynamic> map, String documentId) {
    return ContractTemplate(
      id: documentId,
      title: map['title'] ?? 'Sin título',
      body: map['body'] ?? '',
      // Manejamos la conversión de Timestamp de Firebase a DateTime de Dart
      lastModified: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convierte el objeto a un Mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'updated_at': FieldValue.serverTimestamp(), // Firebase pone la hora del servidor
    };
  }
}