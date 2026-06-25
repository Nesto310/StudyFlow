class FirestoreService {
  const FirestoreService();

  String get status {
    return 'Firestore planejado para uma proxima etapa. '
        'A entrega atual usa SharedPreferences como persistencia local.';
  }
}
