import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// WebView CAS登录组件
/// 
/// 加载吉林大学CAS登录页面，用户完成登录后手动确认并提取Cookie
class WebViewLogin extends StatefulWidget {
  /// 登录成功后重定向到的业务系统URL
  final String serviceUrl;
  
  /// Cookie提取完成回调
  final Function(Map<String, String> cookies) onCookiesExtracted;
  
  const WebViewLogin({
    super.key,
    this.serviceUrl = 'https://iedu.jlu.edu.cn/jwapp/sys/',
    required this.onCookiesExtracted,
  });

  @override
  State<WebViewLogin> createState() => _WebViewLoginState();
}

class _WebViewLoginState extends State<WebViewLogin> {
  late final WebViewController? _controller;
  bool _isLoading = true;
  bool _hasExtractedCookies = false;
  String _currentUrl = '';
  bool _isOnTargetDomain = false; // 是否已在目标域名
  bool _isExtracting = false; // 是否正在提取 cookie
  
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      _controller = null;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    // 构造CAS登录URL
    final casLoginUrl = 'https://cas.jlu.edu.cn/tpass/login?service=${Uri.encodeComponent(widget.serviceUrl)}';
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            print('页面加载开始: $url');
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            print('页面加载完成: $url');
            
            // 检查是否在目标域名（登录成功后会重定向到这些域名）
            try {
              final uri = Uri.parse(url);
              final host = uri.host.toLowerCase();
              print('当前页面域名: $host');
              
              final isTarget = host.contains('iedu.jlu.edu.cn') || 
                               host.contains('i.jlu.edu.cn');
              
              setState(() {
                _isOnTargetDomain = isTarget;
              });
              
              if (isTarget) {
                print('✓ 已成功重定向到业务系统: $host');
              } else {
                print('在登录页面: $host，等待用户完成登录...');
              }
            } catch (e) {
              print('URL解析错误: $e');
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView错误: ${error.description}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('加载失败: ${error.description}')),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            print('导航请求: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(casLoginUrl));
  }

  /// 提取Cookie并返回（手动触发）
  Future<void> _extractAndReturnCookies() async {
    if (_hasExtractedCookies || _isExtracting) return;
    
    setState(() {
      _isExtracting = true;
    });
    
    print('=== 开始提取Cookie ===');
    print('当前URL: $_currentUrl');
    
    try {
      Map<String, String> allCookies = {};
      
      // 方法1：使用WebView CookieManager获取特定域名的所有Cookie
      try {
        final cookieManager = WebViewCookieManager();
        
        // 目标域名列表
        final targetDomains = [
          'iedu.jlu.edu.cn',
          'i.jlu.edu.cn',
        ];
        
        // 已知的Cookie名称（尝试获取这些）
        final knownCookieNames = [
          '_WEU',
          'route',
          'MOD_AUTH_CAS',
          'JSESSIONID',
          'CASTGC',
          'cas_hash',
          'Language',
        ];
        
        print('尝试提取已知Cookie...');
        // 注意：WebViewCookieManager的getCookie方法在新版本中不可用
        // 现在主要使用JavaScript方式提取Cookie
        /*
        for (final domain in targetDomains) {
          for (final cookieName in knownCookieNames) {
            try {
              // getCookie方法不再可用
              final cookieStr = await cookieManager.getCookie(
                WebViewCookie(
                  name: cookieName,
                  value: '',
                  domain: domain,
                  path: '/',
                ),
              );
              
              if (cookieStr != null && cookieStr.isNotEmpty) {
                allCookies[cookieName] = cookieStr;
                print('  ✓ $domain -> $cookieName: ${cookieStr.length} chars');
              }
            } catch (e) {
              // 忽略单个Cookie获取失败
            }
          }
        }
        */
        print('  (跳过WebViewCookieManager提取，使用JavaScript方式)');
        
      } catch (e) {
        print('CookieManager方法失败: $e');
      }
      
      // 方法2：JavaScript提取（主要方法）
      if (_controller != null) {
        try {
          const cookiesScript = 'document.cookie';
          final cookiesString = await _controller!.runJavaScriptReturningResult(cookiesScript);
          
          String cookiesStr = cookiesString.toString().replaceAll('"', '');
          print('JavaScript提取到的Cookie字符串: $cookiesStr');
          
          if (cookiesStr.isNotEmpty && cookiesStr != 'null') {
            final cookiePairs = cookiesStr.split('; ');
            for (final pair in cookiePairs) {
              final parts = pair.split('=');
              if (parts.length >= 2) {
                final key = parts[0].trim();
                final value = parts.sublist(1).join('=');
                if (key.isNotEmpty) {
                  allCookies[key] = value;
                  print('  JS Cookie: $key (${value.length} chars)');
                }
              }
            }
          }
        } catch (e) {
          print('JavaScript提取失败: $e');
        }
      }
      
      // 验证Cookie的有效性
      print('\n=== Cookie验证 ===');
      print('共提取到 ${allCookies.length} 个Cookie');
      
      // 检查是否包含关键Cookie字段
      final hasWEU = allCookies.containsKey('_WEU');
      final hasRoute = allCookies.containsKey('route');
      final hasMOD = allCookies.containsKey('MOD_AUTH_CAS');
      final hasJSESSION = allCookies.containsKey('JSESSIONID');
      final hasCASHash = allCookies.containsKey('cas_hash');
      
      print('关键Cookie检查:');
      print('  _WEU: ${hasWEU ? "✓" : "✗"} ${hasWEU ? "(${allCookies['_WEU']!.length} chars)" : ""}');
      print('  route: ${hasRoute ? "✓" : "✗"}');
      print('  MOD_AUTH_CAS: ${hasMOD ? "✓" : "✗"}');
      print('  JSESSIONID: ${hasJSESSION ? "✓" : "✗"}');
      print('  cas_hash: ${hasCASHash ? "✓" : "✗"}');
      
      // 显示所有Cookie（供调试）
      print('\n所有Cookie详情:');
      allCookies.forEach((key, value) {
        if (value.length > 40) {
          print('  $key = ${value.substring(0, 40)}...');
        } else {
          print('  $key = $value');
        }
      });
      
      // 判断Cookie是否足够（至少要有_WEU或route）
      final isValidCookies = allCookies.isNotEmpty && 
                             (hasWEU || hasRoute);
      
      if (isValidCookies) {
        _hasExtractedCookies = true;
        
        print('\n✓ Cookie验证通过，准备返回');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ 成功提取 ${allCookies.length} 个Cookie'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 800));
          
          // 返回Cookie
          widget.onCookiesExtracted(allCookies);
        }
      } else {
        print('\n✗ Cookie验证失败：未找到关键认证Cookie');
        print('提示：请确保已完成登录并重定向到业务系统页面');
        
        if (mounted) {
          setState(() {
            _isExtracting = false;
          });
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Cookie验证失败'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '可能的原因：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. 未完成登录流程\n'
                               '2. 页面未正确重定向到业务系统\n'
                               '3. 登录失败或验证码错误\n'
                               '4. 网络问题导致Cookie未设置'),
                    const SizedBox(height: 16),
                    const Text(
                      '建议操作：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 点击"刷新重试"重新开始\n'
                               '• 确保输入正确的账号密码\n'
                               '• 等待页面完全加载（看到绿色提示）\n'
                               '• 检查网络连接'),
                    if (allCookies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '调试信息：',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '提取到 ${allCookies.length} 个Cookie，但缺少关键字段',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 刷新页面
                    _controller?.reload();
                    setState(() {
                      _isOnTargetDomain = false;
                      _hasExtractedCookies = false;
                    });
                  },
                  child: const Text('刷新重试'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('知道了'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('提取Cookie异常: $e');
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提取登录信息失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web 平台显示替代方案
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('统一身份认证'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Web 平台登录说明',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '由于浏览器安全限制，Web 版本暂不支持 WebView 登录。\n\n建议使用以下方式：',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.desktop_windows),
                    title: Text('使用 Windows 桌面版'),
                    subtitle: Text('完整功能，推荐使用'),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.phone_android),
                    title: Text('使用移动端应用'),
                    subtitle: Text('Android/iOS 版本'),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final casLoginUrl = 'https://cas.jlu.edu.cn/tpass/login?service=${Uri.encodeComponent(widget.serviceUrl)}';
                    final uri = Uri.parse(casLoginUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('在新窗口中打开登录页面'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 移动端和桌面端使用 WebView
    return PopScope(
      canPop: _hasExtractedCookies,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // 用户点击返回按钮时的确认
        if (!didPop && !_hasExtractedCookies) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('您还未完成登录，确定要退出吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('继续登录'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('退出'),
                ),
              ],
            ),
          );
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('统一身份认证'),
          actions: [
            // 完成登录按钮（当在目标域名时显示）
            if (_isOnTargetDomain && !_isExtracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _extractAndReturnCookies,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('完成登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (_isExtracting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // 刷新按钮
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _controller?.reload();
                setState(() {
                  _isOnTargetDomain = false;
                  _hasExtractedCookies = false;
                  _isExtracting = false;
                });
              },
              tooltip: '刷新页面',
            ),
            // Cookie调试信息
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                await _showCookieDebugInfo();
              },
              tooltip: 'Cookie调试',
            ),
            // 在浏览器中打开
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                if (_currentUrl.isNotEmpty) {
                  final uri = Uri.parse(_currentUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              tooltip: '在浏览器中打开',
            ),
          ],
        ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载登录页面...'),
                  ],
                ),
              ),
            ),
          
          // 登录成功提示（当检测到在目标域名时显示）
          if (_isOnTargetDomain && !_hasExtractedCookies)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '登录成功！',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '请点击右上角"完成登录"按钮',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                   ElevatedButton.icon(
                      onPressed: _extractAndReturnCookies,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('完成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 底部URL显示（调试用）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                _currentUrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      ), // PopScope 的闭合括号
    );
  }

  /// 显示Cookie调试信息
  Future<void> _showCookieDebugInfo() async {
    if (_controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WebView未初始化')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.blue),
            SizedBox(width: 8),
            Text('Cookie调试信息'),
          ],
        ),
        content: FutureBuilder<Map<String, String>>(
          future: _getCookiesForDebug(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 200,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text('获取Cookie失败: ${snapshot.error}');
            }

            final cookies = snapshot.data ?? {};
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '当前URL：',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _currentUrl,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '域名状态：',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isOnTargetDomain ? '✓ 在目标域名' : '✗ 不在目标域名',
                    style: TextStyle(
                      color: _isOnTargetDomain ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cookie (${cookies.length} 个)：',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (cookies.isEmpty)
                    const Text(
                      '未找到Cookie（这可能导致401错误）',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else
                    ...cookies.entries.map((entry) {
                      final isImportant = ['_WEU', 'route', 'MOD_AUTH_CAS', 'JSESSION ID'].contains(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isImportant)
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                if (isImportant) const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              entry.value.length > 50
                                  ? '${entry.value.substring(0, 50)}...'
                                  : entry.value,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (cookies.isNotEmpty) ...[
                    const Divider(height: 16),
                    const Text(
                      '提示：标有★的是关键认证Cookie',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 获取Cookie用于调试显示
  Future<Map<String, String>> _getCookiesForDebug() async {
    final cookies = <String, String>{};

    if (_controller != null) {
      try {
        const cookiesScript = 'document.cookie';
        final cookiesString = await _controller!.runJavaScriptReturningResult(cookiesScript);
        
        String cookiesStr = cookiesString.toString().replaceAll('"', '');
        
        if (cookiesStr.isNotEmpty && cookiesStr != 'null') {
          final cookiePairs = cookiesStr.split('; ');
          for (final pair in cookiePairs) {
            final parts = pair.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=');
              if (key.isNotEmpty) {
                cookies[key] = value;
              }
            }
          }
        }
      } catch (e) {
        print('调试获取Cookie失败: $e');
      }
    }

    return cookies;
  }
}
