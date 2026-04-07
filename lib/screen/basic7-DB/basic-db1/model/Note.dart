class Note {
  final int? id;       // PK (auto increment)
  final String title;  // 제목
  final String content; // 내용
  final String createdAt; // 생성 일시

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  // 객체 -> Map 변환 (DB 저장용)
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt,
  };

  // Map -> 객체 변환 (DB 조회 결과 변환)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
  // 일부 필드만 바꾼 복사본 반환 (수정 시 활용)
  Note copyWith({int? id, String? title, String? content, String? createdAt}) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );

}