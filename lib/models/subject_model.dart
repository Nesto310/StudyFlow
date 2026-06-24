class SubjectModel {
  String? id;
  String nome;

  SubjectModel({
    this.id,
    required this.nome,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
    };
  }

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      nome: map['nome'],
    );
  }
}
