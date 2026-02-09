class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' o 'worker' (operario)

  UserModel({
    required this.uid, 
    required this.email, 
    required this.role
  });

  // Convierte el objeto a un Mapa para enviarlo a Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
    };
  }

  // Crea un UserModel desde un documento de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id, // Usamos el ID del documento de Firestore
      email: map['email'] ?? '',
      role: map['role'] ?? 'worker',
    );
  }

  // Getter útil para comprobaciones rápidas en la UI
  bool get isAdmin => role == 'admin';
}