import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/Todo.dart';

class TodoRepository {
  static final TodoRepository _instance = TodoRepository._internal();
  factory TodoRepository() => _instance;
  TodoRepository._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      path.join(dir.path, 'todos.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE todos (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            title     TEXT    NOT NULL,
            isDone    INTEGER NOT NULL DEFAULT 0,
            priority  TEXT    NOT NULL DEFAULT 'medium',
            createdAt TEXT    NOT NULL
          )
        ''');
        // createdAt 내림차순 인덱스: 커서 기반 조회 성능 향상
        await db.execute(
            'CREATE INDEX idx_createdAt ON todos(createdAt DESC)');
      },
    );
    return _db!;
  }

  // CREATE
  Future<int> create(Todo todo) async {
    final db = await _database;
    return db.insert('todos', todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 커서 기반 페이지네이션 조회
  ///
  /// [cursorCreatedAt] 마지막 로드 항목의 createdAt
  ///   → null 이면 처음부터 조회 (첫 페이지)
  ///   → 값이 있으면 해당 시간보다 오래된 항목 조회 (다음 페이지)
  /// [keyword]  제목 검색어
  /// [limit]    한 번에 가져올 최대 개수
  Future<List<Todo>> findWithCursor({
    String? cursorCreatedAt,
    String keyword = '',
    int limit = 20,
  }) async {
    final db = await _database;
    final conds = <String>[];
    final args = <dynamic>[];

    // 커서 조건: 이전 마지막 항목보다 오래된 것만 조회
    if (cursorCreatedAt != null) {
      conds.add('createdAt < ?');
      args.add(cursorCreatedAt);
    }
    // 제목 검색
    if (keyword.isNotEmpty) {
      conds.add('title LIKE ?');
      args.add('%$keyword%');
    }

    return (await db.query(
      'todos',
      where: conds.isEmpty ? null : conds.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createdAt DESC', // 최신순 (커서 기준)
      limit: limit,
    )).map(Todo.fromMap).toList();
  }

  // UPDATE
  Future<int> update(Todo todo) async {
    final db = await _database;
    return db.update('todos', todo.toMap(),
        where: 'id = ?', whereArgs: [todo.id]);
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await _database;
    return db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // DELETE ALL
  Future<void> deleteAll() async {
    final db = await _database;
    await db.rawDelete('DELETE FROM todos');
  }

  // repositories/todo_repository.dart 에 추가

  /// 더미 데이터 일괄 삽입 (트랜잭션 활용)
  Future<void> insertDummyTodos({
    int count = 30,
    bool mixPriority = true,  // 우선순위 혼합 여부
  }) async {
    const titles = [
      'Flutter Provider 학습',
      'sqflite CRUD 실습',
      '다트 연산자 복습',
      '네트워크 API 연동',
      '상태관리 진화 확인',
      '테스트 코드 작성',
      'UI 컴포넌트 분리',
      '애니메이션 적용',
      '라우팅 설계',
      '프로젝트 배포 준비',
    ];
    const priorities = ['high', 'medium', 'low'];

    final db = await _database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      for (int i = 0; i < count; i++) {
        final priority = mixPriority
            ? priorities[i % priorities.length]
            : 'medium'; // 직접 지정 시 medium 고정
        await txn.insert(
          'todos',
          Todo(
            title: titles[i % titles.length] + ' (${i + 1})',
            priority: priority,
            createdAt: now
                .subtract(Duration(hours: i * 2))
                .toIso8601String(),
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

}