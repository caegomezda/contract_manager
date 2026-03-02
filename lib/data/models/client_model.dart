import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  String? id;
  String name;
  String clientId;
  String email; // NUEVO
  String phone; // NUEVO
  double monto; // NUEVO (usamos double para precisión financiera)
  String contractType;
  String? workerId;
  String? workerName; 
  List<String> addresses;
  String? photoUrl; 
  String? signatureBase64;
  bool termsAccepted;
  DateTime lastUpdate;

  ClientModel({
    this.id,
    required this.name,
    required this.clientId,
    this.email = '', // Valor por defecto
    this.phone = '', // Valor por defecto
    this.monto = 0.0, // Valor por defecto
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
      'client_id': clientId,
      'email': email, // NUEVO
      'phone': phone, // NUEVO
      'monto': monto, // NUEVO
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
    
    // Helper para parsear el monto de forma segura (sea String o num)
    double parsedMonto = 0.0;
    if (data['monto'] != null) {
      parsedMonto = double.tryParse(data['monto'].toString()) ?? 0.0;
    }

    return ClientModel(
      id: snap.id,
      name: data['name'] ?? 'Sin nombre',
      clientId: data['client_id'] ?? data['clientId'] ?? '',
      email: data['email'] ?? '', // NUEVO
      phone: data['phone'] ?? '', // NUEVO
      monto: parsedMonto,         // NUEVO
      contractType: data['contract_type'] ?? data['contractType'] ?? '',
      workerId: data['worker_id'],
      workerName: data['worker_name'],
      addresses: List<String>.from(data['addresses'] ?? []),
      photoUrl: data['photo_data_base64'] ?? data['photoUrl'],
      signatureBase64: data['signature_path'] ?? data['signatureBase64'],
      termsAccepted: data['terms_accepted'] ?? data['termsAccepted'] ?? false,
      lastUpdate: (data['updated_at'] is Timestamp) 
          ? (data['updated_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}