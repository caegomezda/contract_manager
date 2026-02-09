import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  String? id;
  String name;
  String clientId;
  String contractType;
  String? workerId;
  String? workerName; // Añadido para mostrar en el Dashboard Admin
  List<String> addresses;
  String? photoUrl; // Aquí puedes guardar el Base64 de la foto
  String? signatureBase64;
  bool termsAccepted;
  DateTime lastUpdate;

  ClientModel({
    this.id,
    required this.name,
    required this.clientId,
    required this.contractType,
    this.workerId,
    this.workerName,
    required this.addresses,
    this.photoUrl,
    this.signatureBase64,
    this.termsAccepted = false,
    required this.lastUpdate,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'client_id': clientId, // Usamos snake_case para consistencia en DB
      'contract_type': contractType,
      'worker_id': workerId,
      'worker_name': workerName,
      'addresses': addresses,
      'photo_data_base64': photoUrl,
      'signature_path': signatureBase64,
      'terms_accepted': termsAccepted,
      'updated_at': Timestamp.fromDate(lastUpdate),
    };
  }

  // Crear desde Firestore Snapshot
  factory ClientModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return ClientModel(
      id: snap.id,
      name: data['name'] ?? 'Sin nombre',
      clientId: data['client_id'] ?? data['clientId'] ?? '',
      contractType: data['contract_type'] ?? data['contractType'] ?? '',
      workerId: data['worker_id'],
      workerName: data['worker_name'],
      addresses: List<String>.from(data['addresses'] ?? []),
      photoUrl: data['photo_data_base64'] ?? data['photoUrl'],
      signatureBase64: data['signature_path'] ?? data['signatureBase64'],
      termsAccepted: data['terms_accepted'] ?? data['termsAccepted'] ?? false,
      lastUpdate: (data['updated_at'] ?? data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}