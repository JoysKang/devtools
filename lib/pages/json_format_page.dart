import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../src/rust/api/json_format.dart';
import 'dart:async'; // 用于防抖

class JsonFormatPage extends StatefulWidget {
  const JsonFormatPage({super.key});

  @override
  State<JsonFormatPage> createState() => _JsonFormatPageState();
}

class _JsonFormatPageState extends State<JsonFormatPage> {
  // 常量定义
  static const _kIndentOptions = ['2 空格', '4 空格', '压缩', 'Tab'];
  static const _kDebounceMs = 300; // 防抖时间

  // 状态变量
  String _indentSize = '4 空格';
  bool _isFormatting = false;
  Timer? _debounceTimer;

  // 控制器
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  // 输入变化处理（添加防抖）
  void _onInputChanged() {
    final input = _inputController.text;

    // 如果输入为空，立即清空输出
    if (input.isEmpty) {
      _outputController.text = '';
      return;
    }

    // 其他情况使用防抖
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(milliseconds: _kDebounceMs), _formatJson);
  }

  // JSON 格式化处理
  Future<void> _formatJson() async {
    final input = _inputController.text;
    if (input.isEmpty) {
      _outputController.text = '';
      return;
    }

    if (_isFormatting) return;

    setState(() => _isFormatting = true);

    try {
      final formatted = await formatJson(input: input);
      if (mounted) {
        _outputController.text = formatted;
      }
    } catch (e) {
      if (mounted) {
        _outputController.text = '格式化出错: $e';
        _showError('格式化失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isFormatting = false);
      }
    }
  }

  // 错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 复制到剪贴板
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // UI 组件构建方法
  Widget _buildActionButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
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

  Widget _buildIndentSelector() {
    return Row(
      children: [
        const Text('缩进：'),
        PopupMenuButton<String>(
          initialValue: _indentSize,
          onSelected: (value) => setState(() => _indentSize = value),
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
              borderRadius: BorderRadius.circular(4),
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

  Widget _buildInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            _buildActionButton(Icons.search, '搜索', () {/* TODO */}),
          ],
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _inputController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '在此粘贴您的JSON数据...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              Icons.file_copy_outlined,
              '复制',
              () => _copyToClipboard(_outputController.text),
            ),
            _buildActionButton(Icons.search, '搜索', () {/* TODO */}),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _outputController,
                  readOnly: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '格式化输出将显示在这里',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              if (_isFormatting)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
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
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
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
                  Expanded(child: _buildInputArea()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOutputArea()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
