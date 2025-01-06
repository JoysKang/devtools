import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../src/rust/api/json_format.dart';
import 'dart:async';

class JsonFormatPage extends StatefulWidget {
  const JsonFormatPage({super.key});

  @override
  State<JsonFormatPage> createState() => _JsonFormatPageState();
}

class _JsonFormatPageState extends State<JsonFormatPage> {
  // 常量和样式定义
  static const _kIndentOptions = ['2 空格', '4 空格', '压缩', 'Tab'];
  static const _kDebounceMs = 300;

  static const _kTextStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
  );

  static const _kBorderRadius = BorderRadius.all(Radius.circular(4));

  static final _kBorderSide = BorderSide(color: Colors.grey[300]!);

  static final _kBoxDecoration = BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.grey[300]!),
    borderRadius: _kBorderRadius,
  );

  // 状态变量
  String _indentSize = '4 空格';
  bool _isFormatting = false;
  Timer? _debounceTimer;

  // 控制器
  late final TextEditingController _inputController;
  late final TextEditingController _outputController;

  // 搜索相关状态
  bool _showInputSearch = false;
  bool _showOutputSearch = false;
  final TextEditingController _inputSearchController = TextEditingController();
  final TextEditingController _outputSearchController = TextEditingController();
  List<TextSelection> _inputSearchResults = [];
  List<TextSelection> _outputSearchResults = [];
  int _currentInputSearchIndex = -1;
  int _currentOutputSearchIndex = -1;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController()..addListener(_onInputChanged);
    _outputController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.dispose();
    _outputController.dispose();
    _inputSearchController.dispose();
    _outputSearchController.dispose();
    super.dispose();
  }

  // 输入处理
  void _onInputChanged() {
    final input = _inputController.text;
    if (input.isEmpty) {
      _outputController.clear();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: _kDebounceMs),
      _formatJson,
    );
  }

  // 格式化处理
  Future<void> _formatJson() async {
    final input = _inputController.text;
    if (input.isEmpty || _isFormatting) return;

    setState(() => _isFormatting = true);

    try {
      final formatted = await formatJson(
        input: input,
        indentType: _getIndentType(),
      );
      if (mounted) {
        _outputController.text = formatted;
      }
    } catch (e) {
      if (mounted) {
        _outputController.text = '格式化出错: $e';
        _showSnackBar('格式化失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isFormatting = false);
      }
    }
  }

  // 工具方法
  IndentType _getIndentType() {
    switch (_indentSize) {
      case '2 空格':
        return IndentType.spaces2;
      case '4 空格':
        return IndentType.spaces4;
      case 'Tab':
        return IndentType.tab;
      case '压缩':
        return IndentType.none;
      default:
        return IndentType.spaces2;
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      _showSnackBar('已复制到剪贴板');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // UI 组件
  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool readOnly = false,
    String? hintText,
    EdgeInsets? contentPadding,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        contentPadding: contentPadding ?? const EdgeInsets.all(16),
      ),
      style: _kTextStyle,
    );
  }

  // 搜索处理方法
  void _searchInText(String searchText, TextEditingController textController,
      void Function(List<TextSelection>) onResultsFound) {
    if (searchText.isEmpty) {
      onResultsFound([]);
      return;
    }

    final text = textController.text.toLowerCase();
    final searchLower = searchText.toLowerCase();
    final results = <TextSelection>[];

    int start = 0;
    while (true) {
      start = text.indexOf(searchLower, start);
      if (start == -1) break;
      results.add(TextSelection(
        baseOffset: start,
        extentOffset: start + searchText.length,
      ));
      start += searchText.length;
    }

    onResultsFound(results);
  }

  // 搜索框组件
  Widget _buildSearchBar({
    required TextEditingController searchController,
    required VoidCallback onClose,
    required Function(String) onSearch,
    required int currentIndex,
    required int totalResults,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: '搜索...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          if (totalResults > 0) ...[
            Text('${currentIndex + 1}/$totalResults',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: currentIndex > 0
                  ? () => onSearch(searchController.text)
                  : null,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: currentIndex < totalResults - 1
                  ? () => onSearch(searchController.text)
                  : null,
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  // 修改编辑器区域构建方法
  Widget _buildEditorArea({
    required TextEditingController controller,
    required List<Widget> actions,
    required bool isInput,
    bool readOnly = false,
    String? hintText,
  }) {
    final isShowingSearch = isInput ? _showInputSearch : _showOutputSearch;
    final searchController =
        isInput ? _inputSearchController : _outputSearchController;
    final searchResults = isInput ? _inputSearchResults : _outputSearchResults;
    final currentSearchIndex =
        isInput ? _currentInputSearchIndex : _currentOutputSearchIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
        if (isShowingSearch)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildSearchBar(
              searchController: searchController,
              onClose: () => setState(() {
                if (isInput) {
                  _showInputSearch = false;
                  _inputSearchResults.clear();
                } else {
                  _showOutputSearch = false;
                  _outputSearchResults.clear();
                }
              }),
              onSearch: (text) {
                _searchInText(text, controller, (results) {
                  setState(() {
                    if (isInput) {
                      _inputSearchResults = results;
                      _currentInputSearchIndex = results.isEmpty ? -1 : 0;
                    } else {
                      _outputSearchResults = results;
                      _currentOutputSearchIndex = results.isEmpty ? -1 : 0;
                    }
                  });
                });
              },
              currentIndex: currentSearchIndex,
              totalResults: searchResults.length,
            ),
          ),
        Expanded(
          child: Container(
            decoration: _kBoxDecoration,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: _kTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  // 修改搜索按钮的构建
  List<Widget> _buildActionButtons(bool isInput) {
    final List<Widget> actions = [];

    if (isInput) {
      actions.addAll([
        _buildActionButton(
          Icons.paste,
          '粘贴',
          () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              setState(() => _inputController.text = data!.text!);
            }
          },
        ),
        _buildActionButton(
          Icons.file_copy_outlined,
          '复制',
          () => _copyToClipboard(_inputController.text),
        ),
      ]);
    } else {
      actions.add(
        _buildActionButton(
          Icons.file_copy_outlined,
          '复制',
          () => _copyToClipboard(_outputController.text),
        ),
      );
    }

    // 添加搜索按钮
    actions.add(
      _buildActionButton(
        Icons.search,
        '搜索',
        () => setState(() {
          if (isInput) {
            _showInputSearch = !_showInputSearch;
            if (!_showInputSearch) {
              _inputSearchResults.clear();
              _currentInputSearchIndex = -1;
            }
          } else {
            _showOutputSearch = !_showOutputSearch;
            if (!_showOutputSearch) {
              _outputSearchResults.clear();
              _currentOutputSearchIndex = -1;
            }
          }
        }),
      ),
    );

    return actions;
  }

  Widget _buildIndentSelector() {
    return Row(
      children: [
        const Text('缩进：'),
        PopupMenuButton<String>(
          initialValue: _indentSize,
          onSelected: (value) {
            setState(() => _indentSize = value);
            _formatJson();
          },
          itemBuilder: (context) => _kIndentOptions.map((value) {
            return PopupMenuItem<String>(
              value: value,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(value),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: _kBorderRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_indentSize),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: _kBorderSide),
            ),
            child: Row(
              children: [
                const Text(
                  'JSON格式化',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildIndentSelector(),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildEditorArea(
                      controller: _inputController,
                      actions: _buildActionButtons(true),
                      isInput: true,
                      hintText: '在此粘贴您的JSON数据...',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildEditorArea(
                          controller: _outputController,
                          actions: _buildActionButtons(false),
                          isInput: false,
                          readOnly: true,
                          hintText: '格式化输出将显示在这里',
                        ),
                        if (_isFormatting)
                          const Positioned.fill(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
