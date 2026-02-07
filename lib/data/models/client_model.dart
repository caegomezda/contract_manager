import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  String? id;
  String name;
  String clientId;
  String contractType;
  String? workerId;
  List<String> addresses;
  String? photoUrl;
  String? signatureBase64;
  bool termsAccepted;
  DateTime lastUpdate;

  ClientModel({
    this.id,
    required this.name,
    required this.clientId,
    required this.contractType,
    this.workerId,
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
      'clientId': clientId,
      'contractType': contractType,
      'addresses': addresses,
      'photoUrl': photoUrl,
      'signatureBase64': signatureBase64,
      'termsAccepted': termsAccepted,
      'lastUpdate': Timestamp.fromDate(lastUpdate),
    };
  }

  // Crear desde Firestore
  factory ClientModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return ClientModel(
      id: snap.id,
      name: data['name'],
      clientId: data['clientId'],
      contractType: data['contractType'],
      addresses: List<String>.from(data['addresses']),
      photoUrl: data['photoUrl'],
      signatureBase64: data['signatureBase64'],
      termsAccepted: data['termsAccepted'] ?? false,
      lastUpdate: (data['lastUpdate'] as Timestamp).toDate(),
    );
  }
}