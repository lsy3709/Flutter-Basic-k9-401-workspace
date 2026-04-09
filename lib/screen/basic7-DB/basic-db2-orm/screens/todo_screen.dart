import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Todo.dart';
import '../providers/todo_provider.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 스크롤 끝 근처 → loadMore() 호출
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<TodoProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showDialog({Todo? todo}) async {
    final isEdit = todo != null;
    final titleCtrl = TextEditingController(text: todo?.title ?? '');
    String priority = todo?.priority ?? 'medium';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(isEdit ? 'Todo 수정' : 'Todo 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: '우선순위',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'high',   child: Text('🔴 높음')),
                  DropdownMenuItem(value: 'medium', child: Text('🟡 보통')),
                  DropdownMenuItem(value: 'low',    child: Text('🟢 낮음')),
                ],
                onChanged: (v) => setSt(() => priority = v!),
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
                if (title.isEmpty) return;
                final provider = context.read<TodoProvider>();
                if (isEdit) {
                  await provider.updateTodo(
                      todo.copyWith(title: title, priority: priority));
                } else {
                  await provider.addTodo(title, priority);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${todo.title}"을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      context.read<TodoProvider>().deleteTodo(todo.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar ──────────────────────────────────────────────
      appBar: AppBar(
        // titleSpacing을 0으로 설정하여 검색창이 좌우를 충분히 활용하게 합니다.
        titleSpacing: 0,
        title: _showSearch
            ? Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white, // ⚪ 배경색: 흰색
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            // ⚫ 입력 글자 스타일: 검정색
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              hintText: '제목 검색...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onChanged: (v) =>
                context.read<TodoProvider>().loadInitial(keyword: v),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Todo CRUD (Provider)'),
            Selector<TodoProvider, int>(
              selector: (_, p) => p.doneCount,
              builder: (_, count, __) => Text(
                '완료: $count건',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          // ✅ 더미 데이터 생성 버튼
          IconButton(
            icon: const Icon(Icons.data_array),
            tooltip: '더미 데이터 생성',
            onPressed: _showDummyDialog,
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  context.read<TodoProvider>().loadInitial();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => context.read<TodoProvider>().deleteAll(),
          ),
        ],
      ),

      // ── Body ────────────────────────────────────────────────
      body: Consumer<TodoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: provider.clearError,
                    child: const Text('닫기'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 검색 배너
              if (provider.keyword.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  color: Colors.blue.shade50,
                  child: Text(
                    '"${provider.keyword}" 검색 결과',
                    style: TextStyle(
                        color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),

              // 무한 스크롤 목록
              Expanded(
                child: provider.todos.isEmpty
                    ? const Center(child: Text('할 일이 없습니다.'))
                    : ListView.separated(
                  controller: _scrollCtrl,
                  itemCount: provider.todos.length + 1,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // 마지막 셀: 로딩 또는 완료 메시지
                    if (index == provider.todos.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: provider.isLoadingMore
                              ? const CircularProgressIndicator()
                              : Text(
                            provider.hasMore
                                ? ''
                                : '모든 항목을 불러왔습니다.',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13),
                          ),
                        ),
                      );
                    }

                    final todo = provider.todos[index];
                    return ListTile(
                      leading: Checkbox(
                        value: todo.isDone,
                        onChanged: (_) =>
                            context.read<TodoProvider>().toggleDone(todo),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: todo.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.isDone ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        todo.createdAt.substring(0, 10),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 우선순위 배지
                          _PriorityBadge(todo.priority),
                          // 수정 버튼
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 20),
                            onPressed: () =>
                                _showDialog(todo: todo),
                          ),
                          // 삭제 버튼
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            onPressed: () => _confirmDelete(todo),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ── 추가 버튼 (FAB) ─────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        tooltip: 'Todo 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  // _TodoScreenState 안에 추가

  /// 더미 데이터 확인 다이얼로그
  Future<void> _showDummyDialog() async {
    int selectedCount = 30;
    bool mixPriority = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.data_array, color: Colors.green),
              SizedBox(width: 8),
              Text('더미 데이터 생성'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 건수 선택
              DropdownButtonFormField<int>(
                value: selectedCount,
                decoration: const InputDecoration(
                  labelText: '삽입 건수',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 10,  child: Text('10건')),
                  DropdownMenuItem(value: 30,  child: Text('30건')),
                  DropdownMenuItem(value: 50,  child: Text('50건')),
                  DropdownMenuItem(value: 100, child: Text('100건')),
                ],
                onChanged: (v) => setDlg(() => selectedCount = v!),
              ),
              const SizedBox(height: 12),
              // 우선순위 혼합 옵션
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('우선순위 혼합'),
                subtitle: const Text('high / medium / low 순환'),
                value: mixPriority,
                onChanged: (v) => setDlg(() => mixPriority = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt),
              label: const Text('생성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Provider 호출 → 로딩 상태는 Provider가 자동 업데이트
    await context.read<TodoProvider>().insertDummyData(
      count: selectedCount,
      mixPriority: mixPriority,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 더미 데이터 $selectedCount건이 추가되었습니다.'),
        backgroundColor: Colors.green,
      ),
    );
  }

}

// 우선순위 배지 위젯
class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge(this.priority);

  Color get _color {
    switch (priority) {
      case 'high': return Colors.red;
      case 'low':  return Colors.green;
      default:     return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}