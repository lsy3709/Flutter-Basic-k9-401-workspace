import 'package:flutter/material.dart';

import '../models/Todo.dart';
import '../repositories/TodoRepository.dart';


/// Todo DB 상태 + 커서 기반 무한 스크롤을 관리하는 Provider
class TodoProvider extends ChangeNotifier {
  final TodoRepository _repo = TodoRepository();

  List<Todo> _todos = [];
  bool _isLoading = false;       // 초기·리셋 로딩
  bool _isLoadingMore = false;   // 추가 페이지 로딩
  bool _hasMore = true;          // 더 불러올 데이터 존재 여부
  String? _cursor;               // 커서: 마지막 항목의 createdAt
  String? _errorMessage;
  String _keyword = '';
  static const int _pageSize = 20;

  // ── Getters ──────────────────────────────────────────────────
  List<Todo> get todos         => List.unmodifiable(_todos);
  bool       get isLoading     => _isLoading;
  bool       get isLoadingMore => _isLoadingMore;
  bool       get hasMore       => _hasMore;
  String?    get errorMessage  => _errorMessage;
  String     get keyword       => _keyword;
  int        get doneCount     => _todos.where((t) => t.isDone).length;

  // ── 초기 로드 / 검색어 변경 시 호출 ─────────────────────────

  /// 목록 초기화 후 첫 페이지 로드
  Future<void> loadInitial({String keyword = ''}) async {
    _keyword = keyword;
    _isLoading = true;
    _todos = [];
    _cursor = null;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final items = await _repo.findWithCursor(
          keyword: _keyword, limit: _pageSize);
      _todos = items;
      _hasMore = items.length == _pageSize;
      if (items.isNotEmpty) _cursor = items.last.createdAt;
    } catch (e) {
      _errorMessage = '로드 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 스크롤 끝 도달 시 다음 페이지 추가 로드
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final items = await _repo.findWithCursor(
        cursorCreatedAt: _cursor,
        keyword: _keyword,
        limit: _pageSize,
      );
      _todos.addAll(items);
      _hasMore = items.length == _pageSize;
      if (items.isNotEmpty) _cursor = items.last.createdAt;
    } catch (e) {
      _errorMessage = '추가 로드 실패: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── CRUD 메서드 ───────────────────────────────────────────────

  Future<void> addTodo(String title, String priority) async {
    if (title.trim().isEmpty) return;
    try {
      await _repo.create(Todo(
        title: title.trim(),
        priority: priority,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await loadInitial(keyword: _keyword); // 추가 후 목록 리셋
    } catch (e) {
      _errorMessage = '추가 실패: $e';
      notifyListeners();
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      await _repo.update(todo);
      await loadInitial(keyword: _keyword);
    } catch (e) {
      _errorMessage = '수정 실패: $e';
      notifyListeners();
    }
  }

  Future<void> toggleDone(Todo todo) async {
    try {
      await _repo.update(todo.copyWith(isDone: !todo.isDone));
      await loadInitial(keyword: _keyword);
    } catch (e) {
      _errorMessage = '수정 실패: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _repo.delete(id);
      await loadInitial(keyword: _keyword);
    } catch (e) {
      _errorMessage = '삭제 실패: $e';
      notifyListeners();
    }
  }

  Future<void> deleteAll() async {
    try {
      await _repo.deleteAll();
      await loadInitial();
    } catch (e) {
      _errorMessage = '전체 삭제 실패: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // providers/todo_provider.dart 의 CRUD 메서드 영역에 추가

  /// 더미 데이터 일괄 삽입
  Future<void> insertDummyData({
    int count = 30,
    bool mixPriority = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.insertDummyTodos(
        count: count,
        mixPriority: mixPriority,
      );
      // 삽입 후 목록 첫 페이지로 리로드
      await loadInitial(keyword: _keyword);
    } catch (e) {
      _errorMessage = '더미 데이터 삽입 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}