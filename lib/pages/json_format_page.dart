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

  Widget _buildEditorArea({
    required TextEditingController controller,
    required List<Widget> actions,
    bool readOnly = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
        Expanded(
          child: Container(
            decoration: _kBoxDecoration,
            child: _buildTextField(
              controller: controller,
              readOnly: readOnly,
              hintText: hintText,
            ),
          ),
        ),
      ],
    );
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
                      hintText: '在此粘贴您的JSON数据...',
                      actions: [
                        _buildActionButton(
                          Icons.paste,
                          '粘贴',
                          () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              setState(
                                  () => _inputController.text = data!.text!);
                            }
                          },
                        ),
                        _buildActionButton(
                          Icons.file_copy_outlined,
                          '复制',
                          () => _copyToClipboard(_inputController.text),
                        ),
                        _buildActionButton(
                          Icons.search,
                          '搜索',
                          () {/* TODO */},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildEditorArea(
                          controller: _outputController,
                          readOnly: true,
                          hintText: '格式化输出将显示在这里',
                          actions: [
                            _buildActionButton(
                              Icons.file_copy_outlined,
                              '复制',
                              () => _copyToClipboard(_outputController.text),
                            ),
                            _buildActionButton(
                              Icons.search,
                              '搜索',
                              () {/* TODO */},
                            ),
                          ],
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
