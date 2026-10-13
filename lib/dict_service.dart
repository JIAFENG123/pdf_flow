import 'dart:convert';
import 'package:http/http.dart' as http;

class DictResult {
  final String word;
  final String phonetic;
  final List<String> meanings;
  final String? example;

  DictResult({
    required this.word,
    required this.phonetic,
    required this.meanings,
    this.example,
  });
}

class DictionaryService {
  // 内存缓存，避免重复网络请求
  static final Map<String, DictResult> _cache = {};

  // 基础高频词离线秒开词库
  static final Map<String, DictResult> _localFallback = {
    'the': DictResult(word: 'the', phonetic: '/ðə/', meanings: ['art. 定冠词，这，那']),
    'book': DictResult(word: 'book', phonetic: '/bʊk/', meanings: ['n. 书，书籍', 'v. 预订，登记'], example: 'I am reading a good book.'),
    'read': DictResult(word: 'read', phonetic: '/riːd/', meanings: ['v. 阅读，朗读', 'n. 读物'], example: 'She reads books every day.'),
    'pdf': DictResult(word: 'PDF', phonetic: '/ˌpiː diː ˈef/', meanings: ['abbr. 便携式文档格式 (Portable Document Format)']),
    'flow': DictResult(word: 'flow', phonetic: '/fləʊ/', meanings: ['v. 流动，循环', 'n. 流畅，水流'], example: 'The river flows smoothly.'),
    'page': DictResult(word: 'page', phonetic: '/peɪdʒ/', meanings: ['n. 页，页面', 'v. 翻页，呼叫'], example: 'Turn to page 10.'),
    'chapter': DictResult(word: 'chapter', phonetic: '/ˈtʃæptə(r)/', meanings: ['n. 章节，回，篇章']),
    'content': DictResult(word: 'content', phonetic: '/ˈkɒntent/', meanings: ['n. 内容，目录', 'adj. 满意的']),
    'reader': DictResult(word: 'reader', phonetic: '/ˈriːdə(r)/', meanings: ['n. 读者，读本，阅读器']),
    'summary': DictResult(word: 'summary', phonetic: '/ˈsʌməri/', meanings: ['n. 摘要，大纲，概要']),
  };

  /// 综合查词/翻译接口
  /// 支持单个英语单词查词（音标+中文词义）或任意句子长文本划词翻译
  static Future<DictResult> lookup(String rawText) async {
    final cleanText = rawText.trim();
    if (cleanText.isEmpty) {
      return DictResult(word: '', phonetic: '', meanings: ['未检测到内容']);
    }

    final key = cleanText.toLowerCase();
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    if (_localFallback.containsKey(key)) {
      return _localFallback[key]!;
    }

    // 判断是单个单词还是多词短语/句子
    final isSingleWord = !cleanText.contains(' ') && cleanText.length < 30;

    if (isSingleWord) {
      final wordResult = await _lookupSingleWord(cleanText);
      if (wordResult != null) {
        _cache[key] = wordResult;
        return wordResult;
      }
    }

    // 多词或单词查词未命中时，使用全文翻译引擎
    final transResult = await _translateSentence(cleanText);
    _cache[key] = transResult;
    return transResult;
  }

  /// 查单词：优先有道词典，获取英汉释义 + 音标
  static Future<DictResult?> _lookupSingleWord(String word) async {
    try {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final uri = Uri.parse('https://dict.youdao.com/jsonapi?q=${Uri.encodeComponent(cleanWord)}');
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        String phonetic = '';
        final List<String> meanings = [];

        // 提取音标
        if (data['ec'] != null && data['ec']['word'] != null && (data['ec']['word'] as List).isNotEmpty) {
          final wordInfo = data['ec']['word'][0];
          final uk = wordInfo['ukphone'] ?? '';
          final us = wordInfo['usphone'] ?? '';
          if (uk.toString().isNotEmpty) {
            phonetic = '/$uk/';
          } else if (us.toString().isNotEmpty) {
            phonetic = '/$us/';
          }

          // 提取中文词义
          final trs = wordInfo['trs'] as List?;
          if (trs != null) {
            for (var tr in trs) {
              final l = tr['tr']?[0]?['l']?['i'];
              if (l != null && (l as List).isNotEmpty) {
                meanings.add(l[0].toString());
              }
            }
          }
        }

        // 若 EC 无结果，尝试 web_trans 网络释义
        if (meanings.isEmpty && data['web_trans'] != null) {
          final webTrans = data['web_trans']['web-translation'] as List?;
          if (webTrans != null && webTrans.isNotEmpty) {
            final trans = webTrans[0]['trans'] as List?;
            if (trans != null && trans.isNotEmpty) {
              final val = trans[0]['value']?.toString() ?? '';
              if (val.isNotEmpty) meanings.add(val);
            }
          }
        }

        if (meanings.isNotEmpty) {
          return DictResult(
            word: word,
            phonetic: phonetic,
            meanings: meanings,
          );
        }
      }
    } catch (_) {
      // 降级到 suggest 快速接口
      try {
        final uri = Uri.parse('https://dict.youdao.com/suggest?q=${Uri.encodeComponent(word)}&num=1&doctype=json');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final entries = data['data']?['entries'] as List?;
          if (entries != null && entries.isNotEmpty) {
            final explain = entries[0]['explain']?.toString() ?? '';
            if (explain.isNotEmpty) {
              return DictResult(
                word: word,
                phonetic: '',
                meanings: [explain],
              );
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// 翻译短语/整句：通过权威翻译服务直接译成中文
  static Future<DictResult> _translateSentence(String text) async {
    try {
      // 判断语言方向
      final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
      final langPair = isChinese ? 'zh|en' : 'en|zh-CN';

      final uri = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$langPair');
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final translatedText = data['responseData']?['translatedText']?.toString() ?? '';
        if (translatedText.isNotEmpty && translatedText != text) {
          return DictResult(
            word: text,
            phonetic: '',
            meanings: [translatedText],
          );
        }
      }
    } catch (_) {}

    return DictResult(
      word: text,
      phonetic: '',
      meanings: ['暂未获取到翻译结果，请检查网络连接'],
    );
  }
}
