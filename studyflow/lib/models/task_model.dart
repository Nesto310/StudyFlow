class TaskModel {
  String? id;
  String titulo;
  String disciplina;
  String prazo;
  String status;

  TaskModel({
    this.id,
    required this.titulo,
    required this.disciplina,
    required this.prazo,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'disciplina': disciplina,
      'prazo': prazo,
      'status': status,
    };
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      titulo: map['titulo'],
      disciplina: map['disciplina'],
      prazo: map['prazo'],
      status: map['status'],
    );
  }
}
