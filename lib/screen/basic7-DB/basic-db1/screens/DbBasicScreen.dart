import 'package:flutter/material.dart';

import '../model/Note.dart';
import '../service/DatabaseHelper.dart';

class DbBasicScreen extends StatefulWidget {
  const DbBasicScreen({super.key});
  @override
  State<DbBasicScreen> createState() => _DbBasicScreenState();
}

class _DbBasicScreenState extends State<DbBasicScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Note> _notes = [];
  int _totalCount = 0;
  int _currentPage = 0;
  static const int _pageSize = 10; // 페이지당 항목 수

  String _keyword = '';
  bool _showSearch = false;          // 검색창 표시 여부
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // 노트 목록 + 전체 건수 로드
  Future<void> _load() async {
    final notes = await _db.getNotes(
      keyword: _keyword,
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );
    final count = await _db.getCount(keyword: _keyword);
    setState(() {
      _notes = notes;
      _totalCount = count;
    });
  }

  // 총 페이지 수
  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 9999);

  // ── 추가 / 수정 다이얼로그 ─────────────────────────────
  Future<void> _showNoteDialog({Note? note}) async {
    final isEdit = note != null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '노트 수정' : '노트 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text.trim();
              if (title.isEmpty) return;
              if (isEdit) {
                // 기존 노트 수정: copyWith로 변경 필드만 교체
                await _db.updateNote(
                    note.copyWith(title: title, content: content));
              } else {
                // 새 노트 추가
                await _db.insertNote(Note(
                  title: title,
                  content: content,
                  createdAt: DateTime.now().toIso8601String(),
                ));
                _currentPage = 0; // 추가 후 첫 페이지로
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: Text(isEdit ? '수정' : '추가'),
          ),
        ],
      ),
    );
  }

  // ── 삭제 확인 다이얼로그 ──────────────────────────────
  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${note.title}"을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteNote(note.id!);
      // 마지막 페이지의 마지막 항목 삭제 시 이전 페이지로 이동
      if (_notes.length == 1 && _currentPage > 0) _currentPage--;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar ─────────────────────────────────────────
      // ── AppBar ─────────────────────────────────────────
      appBar: AppBar(
        // titleSpacing을 0으로 설정하여 입력창 공간을 최대로 확보합니다.
        titleSpacing: 0,
        title: _showSearch
            ? Padding(
          // 좌우 여백을 주어 아이콘과 겹치지 않게 조절합니다.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            // 🔴 수정 1: 텍스트를 수직 중앙으로 정렬 (한글 깨짐 방지 핵심)
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '검색어 입력...',
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
              // 🔴 수정 2: 내부 여백을 주어 글자 위아래가 잘리지 않게 함
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            // 🔴 수정 3: 폰트 스타일을 명시적으로 지정
            style: const TextStyle(color: Colors.white, fontSize: 18),
            cursorColor: Colors.white,
            onChanged: (v) {
              // 🔴 수정 4: 검색어 변경 시 즉시 UI 반영을 위해 setState 추가
              setState(() {
                _keyword = v;
                _currentPage = 0;
              });
              _load();
            },
          ),
        )
            : const Text('내부 DB 기초'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _keyword = '';
                  _currentPage = 0;
                  _load();
                }
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── 검색 결과 배너 ────────────────────────────
          if (_keyword.isNotEmpty)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.blue.shade50,
              child: Text(
                '"$_keyword" 검색 결과: $_totalCount건',
                style:
                TextStyle(color: Colors.blue.shade700, fontSize: 13),
              ),
            ),

          // ── 노트 목록 ─────────────────────────────────
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('노트가 없습니다.'))
                : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _notes.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return ListTile(
                  title: Text(
                    note.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        note.createdAt.substring(0, 10),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 수정 버튼
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue),
                        onPressed: () =>
                            _showNoteDialog(note: note),
                      ),
                      // 삭제 버튼
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () => _confirmDelete(note),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── 페이지네이션 바 ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이전 페이지
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () {
                    setState(() => _currentPage--);
                    _load();
                  }
                      : null,
                ),
                // 현재 페이지 / 전체 페이지 표시
                Text(
                  '${_currentPage + 1} / $_totalPages  (전체 $_totalCount건)',
                  style: const TextStyle(fontSize: 13),
                ),
                // 다음 페이지
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                    setState(() => _currentPage++);
                    _load();
                  }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),

      // ── 추가 버튼 (FAB) ────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        tooltip: '노트 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}