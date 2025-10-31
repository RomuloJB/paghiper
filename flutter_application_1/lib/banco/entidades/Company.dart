class Company {
  final int? id;
  final String name;
  final String? cnpj;
  final String createdAt;

  const Company({
    this.id,
    required this.name,
    this.cnpj,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'cnpj': cnpj,
      'created_at': createdAt,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      name: map['name'] as String,
      cnpj: map['cnpj'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? cnpj,
    String? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
