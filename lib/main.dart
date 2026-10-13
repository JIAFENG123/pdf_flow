import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dict_service.dart';

void main() {
  runApp(const PdfFlowApp());
}

class PdfFlowApp extends StatelessWidget {
  const PdfFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PdfFlow - 微信读书风格',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5F0), // 微信读书经典纸书米黄色
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF141414),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    // 2.2 秒后平滑无缝进入主界面
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0), // 微信读书经典羊皮米色
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // 精致 App Logo 阴影卡片
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C3E50).withAlpha(35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 应用名称
                  const Text(
                    'PdfFlow',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: 1.5,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 沉浸式 Slogan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 1,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '沉浸阅读 · 心流所至',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 18,
                        height: 1,
                        color: const Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  // 底部雅致品牌标示
                  const Text(
                    '微信读书式极简翻页与即时查词体验',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentFiles = prefs.getStringList('recent_pdfs') ?? [];
    });
  }

  Future<void> _saveRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    _recentFiles.remove(path);
    _recentFiles.insert(0, path);
    if (_recentFiles.length > 20) {
      _recentFiles = _recentFiles.sublist(0, 20);
    }
    await prefs.setStringList('recent_pdfs', _recentFiles);
    setState(() {});
  }

  // 移出书架
  Future<void> _removeRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentFiles.remove(path);
    });
    await prefs.setStringList('recent_pdfs', _recentFiles);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已从书架移出'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '撤销',
            onPressed: () => _saveRecentFile(path),
          ),
        ),
      );
    }
  }

  void _showBookOptionsMenu(String filePath, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.brown.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.brown, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filePath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('从书架移出', style: TextStyle(color: Colors.redAccent)),
                subtitle: const Text('仅从书架记录中移除，不会删除手机原始文件', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removeRecentFile(filePath);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndOpenFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final filePath = files.first.path!;
      await _saveRecentFile(filePath);
      if (!mounted) return;
      _openViewer(filePath);
    }
  }

  void _openViewer(String filePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(filePath: filePath),
      ),
    ).then((_) => _loadRecentFiles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: Colors.brown),
            SizedBox(width: 10),
            Text('书架', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
      ),
      body: _recentFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.import_contacts_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '书架暂无书籍',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '导入 PDF，享受微信读书纯正左右翻页与划词气泡翻译',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _pickAndOpenFile,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('从手机导入 PDF'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _recentFiles.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final filePath = _recentFiles[index];
                final fileName = filePath.split(Platform.pathSeparator).last;
                final fileExists = File(filePath).existsSync();

                return Dismissible(
                  key: Key(filePath),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(220),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.white),
                        SizedBox(width: 6),
                        Text('移出书架', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    _removeRecentFile(filePath);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    leading: Container(
                      width: 44,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.brown.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.brown),
                    ),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      fileExists ? filePath : '文件不存在或已被移动',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: fileExists ? null : Colors.redAccent,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          tooltip: '更多操作',
                          onPressed: () => _showBookOptionsMenu(filePath, fileName),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                      ],
                    ),
                    onLongPress: () => _showBookOptionsMenu(filePath, fileName),
                    onTap: () {
                      if (fileExists) {
                        _openViewer(filePath);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('文件不存在或已被删除')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndOpenFile,
        icon: const Icon(Icons.add_rounded),
        label: const Text('导入书籍'),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = false;
  bool _nightMode = false;
  final FlutterTts _flutterTts = FlutterTts();

  // 微信读书悬浮操作菜单 (复制 / 翻译 / 划线 / 朗读)
  OverlayEntry? _menuOverlay;
  bool _isTextSelected = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(clean);
    await _flutterTts.setLanguage(isChinese ? 'zh-CN' : 'en-US');
    await _flutterTts.stop();
    await _flutterTts.speak(clean);
  }

  @override
  void dispose() {
    _removeMenu();
    _flutterTts.stop();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _removeMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    if (_isTextSelected) {
      setState(() {
        _isTextSelected = false;
      });
    }
  }

  // 微信读书式划词专属操作菜单（替代原生菜单和冲突气泡）
  void _showWeChatStyleMenu(PdfTextSelectionChangedDetails details) {
    _removeMenu();

    final text = details.selectedText?.trim() ?? '';
    if (text.isEmpty) return;

    if (!_isTextSelected) {
      setState(() {
        _isTextSelected = true;
      });
    }

    final globalSelectedRegion = details.globalSelectedRegion;
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    // 计算菜单位置：置于选区上方，超出屏幕则放下方
    double top = screenSize.height / 2;
    double left = 24.0;
    if (globalSelectedRegion != null) {
      top = globalSelectedRegion.top - 62;
      if (top < 70) {
        top = globalSelectedRegion.bottom + 12;
      }
      left = (globalSelectedRegion.left + globalSelectedRegion.width / 2 - 140)
          .clamp(16.0, screenSize.width - 296.0);
    }

    _menuOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 点击外部透明层取消选中与关闭菜单
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeMenu();
                  _pdfViewerController.clearSelection();
                },
              ),
            ),
            Positioned(
              top: top,
              left: left,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withAlpha(245), // 微信读书深黑沉浸胶囊
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(90),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white24, width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 翻译按钮
                      _buildMenuItem(
                        icon: Icons.translate_rounded,
                        label: '翻译',
                        onTap: () {
                          _removeMenu();
                          _showTranslationSheet(text);
                        },
                      ),
                      _buildMenuDivider(),
                      // 复制按钮
                      _buildMenuItem(
                        icon: Icons.copy_rounded,
                        label: '复制',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: text));
                          _removeMenu();
                          _pdfViewerController.clearSelection();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已复制到剪贴板'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      _buildMenuDivider(),
                      // 朗读按钮
                      _buildMenuItem(
                        icon: Icons.volume_up_rounded,
                        label: '朗读',
                        onTap: () {
                          _removeMenu();
                          _speakText(text);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_menuOverlay!);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFD54F), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white24,
    );
  }

  // 微信读书经典雅致底部翻译面板（消除高度跳动与闪烁）
  void _showTranslationSheet(String selectedText) {
    // 1. 预先创建 Future 实例，避免 build 重新触发或网络更新时反复重绘 FutureBuilder
    final lookupFuture = DictionaryService.lookup(selectedText);

    // 2. 及时清除当前 PDF 选区，防止底层的选区状态重绘与 bottom sheet 动画冲突
    _pdfViewerController.clearSelection();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) {
        final isDark = _nightMode || Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // 顶部拖动条
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 标题栏：原文与操作
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          selectedText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: selectedText.contains(' ') ? 16 : 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded),
                        color: const Color(0xFFD4AF37),
                        tooltip: '朗读',
                        onPressed: () => _speakText(selectedText),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: '复制原文',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: selectedText));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('已复制原文'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                  const SizedBox(height: 16),
                  // 翻译结果区域
                  FutureBuilder<DictResult>(
                    future: lookupFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('正在解析释义与翻译...', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      final dict = snapshot.data;
                      if (dict == null || dict.meanings.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: Text('未能获取到释义，请检查网络')),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dict.phonetic.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dict.phonetic,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ...dict.meanings.map((m) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9F7F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : Colors.black.withAlpha(8),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2, right: 8),
                                      child: Icon(Icons.arrow_right_rounded, size: 18, color: Color(0xFFD4AF37)),
                                    ),
                                    Expanded(
                                      child: Text(
                                        m,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.45,
                                          color: isDark ? Colors.white70 : const Color(0xFF333333),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (dict.example != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '例句: "${dict.example}"',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.amber[200] : Colors.brown[800],
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    final isDark = _nightMode || Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF7F5F0),
      body: GestureDetector(
        onTap: () {
          // 轻触屏幕收起操作菜单
          if (_menuOverlay != null) {
            _removeMenu();
            _pdfViewerController.clearSelection();
          } else {
            setState(() {
              _showControls = !_showControls;
            });
          }
        },
        child: Stack(
          children: [
            // 工业级严格单页横向吸附翻页渲染器（一页一屏，绝无横向长卷轴）
            ColorFiltered(
              colorFilter: _nightMode
                  ? const ColorFilter.matrix([
                      -1,  0,  0, 0, 255,
                       0, -1,  0, 0, 255,
                       0,  0, -1, 0, 255,
                       0,  0,  0, 1,   0,
                    ])
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: SfPdfViewer.file(
                File(widget.filePath),
                controller: _pdfViewerController,
                scrollDirection: PdfScrollDirection.horizontal,
                pageLayoutMode: PdfPageLayoutMode.single, // 关键：严格单页独立卡片吸附！
                canShowScrollHead: false,
                canShowScrollStatus: false,
                canShowPaginationDialog: false,
                canShowTextSelectionMenu: false, // 禁用系统默认弹窗，彻底杜绝菜单与弹窗双重冲突！
                enableDoubleTapZooming: true,
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                  });
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  _removeMenu();
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
                onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                  if (details.selectedText != null && details.selectedText!.trim().isNotEmpty) {
                    _showWeChatStyleMenu(details);
                  } else {
                    _removeMenu();
                  }
                },
              ),
            ),

            // 微信读书式两侧轻触翻页区域（选中文本时自动禁用，宽度收敛为28px避免误触）
            if (!_isTextSelected) ...[
              Positioned(
                left: 0,
                top: 120,
                bottom: 120,
                width: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _removeMenu();
                    _pdfViewerController.previousPage();
                  },
                ),
              ),
              Positioned(
                right: 0,
                top: 120,
                bottom: 120,
                width: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _removeMenu();
                    _pdfViewerController.nextPage();
                  },
                ),
              ),
            ],

            // 微信读书沉浸全屏底部常驻极简胶囊页码
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showControls ? 0.0 : 0.85,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(70),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 顶部导航栏（点击中间滑出）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _showControls ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withAlpha(245),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_nightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                            tooltip: '护眼/夜间模式',
                            onPressed: () {
                              setState(() {
                                _nightMode = !_nightMode;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 底部控制面板（滑动进度条 + 页面跳转）
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _showControls ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withAlpha(245),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_totalPages > 0)
                            Row(
                              children: [
                                Text(
                                  '$_currentPage',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _currentPage.toDouble().clamp(1.0, _totalPages.toDouble()),
                                    min: 1.0,
                                    max: _totalPages.toDouble(),
                                    divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                                    onChanged: (val) {
                                      _pdfViewerController.jumpToPage(val.toInt());
                                    },
                                  ),
                                ),
                                Text(
                                  '$_totalPages',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                onPressed: () => _pdfViewerController.previousPage(),
                                icon: const Icon(Icons.chevron_left_rounded),
                                label: const Text('上一页'),
                              ),
                              Text(
                                '$_currentPage / $_totalPages 页',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              TextButton(
                                onPressed: () => _pdfViewerController.nextPage(),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('下一页'),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
