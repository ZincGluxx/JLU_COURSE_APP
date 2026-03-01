import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 吉林大学金智教务系统 API 服务
/// 
/// Cookie管理服务
/// 课程数据通过WebView导入，不再使用API获取
class JluApiService {
  static const String baseUrl = 'https://iedu.jlu.edu.cn';
  
  // 创建一个接受所有证书的HTTP客户端（仅用于开发/测试）
  static http.Client _createHttpClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 在生产环境中应该验证证书，这里仅用于开发
        print('警告: 跳过证书验证 for $host:$port');
        return true; // 接受所有证书
      };
    return IOClient(ioClient);
  }

  final http.Client _client = _createHttpClient();
  String? _cookie;
  // Token storage handled via cookies and session management
  bool _isLoggedIn = false;

  /// 检查是否已登录
  bool get isLoggedIn => _isLoggedIn;

  /// 通过WebView登录获取的Cookie设置登录状态
  /// 
  /// [cookies] 从WebView提取的Cookie Map
  /// [username] 可选的用户名，用于保存凭证
  /// 
  /// 返回: 设置是否成功
  Future<bool> setLoginCookies(Map<String, String> cookies, {String? username}) async {
    try {
      print('=== 开始设置Cookie ===');
      print('收到 ${cookies.length} 个Cookie字段');
      cookies.forEach((key, value) {
        print('  - $key: ${value.length} 字符');
      });
      
      // 构建Cookie字符串
      final cookieString = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      
      if (cookieString.isEmpty) {
        print('❌ Cookie为空');
        return false;
      }
      
      _cookie = cookieString;
      _isLoggedIn = true;
      
      print('Cookie设置成功，包含 ${cookies.length} 个字段');
      
      // 始终保存Cookie到本地，以便其他实例可以使用
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_cookies', cookieString);
      await prefs.setInt('cookie_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      // 如果提供了用户名，同时保存用户名
      if (username != null) {
        await prefs.setString('username', username);
      }
      
      print('Cookie已保存到本地存储');
      
      return true;
    } catch (e) {
      print('设置Cookie异常: $e');
      return false;
    }
  }

  /// 尝试使用保存的Cookie恢复登录状态
  /// 
  /// 返回: 恢复是否成功
  Future<bool> restoreLoginFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCookies = prefs.getString('saved_cookies');
      final timestamp = prefs.getInt('cookie_timestamp');
      
      if (savedCookies == null || timestamp == null) {
        print('没有保存的Cookie');
        return false;
      }
      
      // 检查Cookie是否过期（24小时）
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > 24 * 60 * 60 * 1000) {
        print('Cookie已过期');
        return false;
      }
      
      _cookie = savedCookies;
      _isLoggedIn = true;
      print('从缓存恢复登录状态成功');
      print('Cookie内容预览: ${savedCookies.substring(0, savedCookies.length > 50 ? 50 : savedCookies.length)}...');
      print('Cookie包含的字段: ${savedCookies.split('; ').map((c) => c.split('=')[0]).join(', ')}');
      
      return true;
    } catch (e) {
      print('恢复登录状态异常: $e');
      return false;
    }
  }

  /// 登录到金智教务系统 (已弃用 - 使用WebView登录)
  /// 
  /// 注意: 此方法已不再使用。请使用 WebViewLogin 组件进行登录，
  /// 然后调用 setLoginCookies() 设置Cookie。
  /// 
  /// [username] 学号
  /// [password] 密码
  /// 
  /// 返回: 登录是否成功
  @Deprecated('使用 WebViewLogin 组件和 setLoginCookies() 方法替代')
  Future<bool> login(String username, String password) async {
    print('警告: login() 方法已弃用，请使用 WebViewLogin 组件');
    return false;
  }

  /// 登出
  Future<void> logout() async {
    _cookie = null;
    _isLoggedIn = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('saved_cookies');
    await prefs.remove('cookie_timestamp');
    
    print('已清除所有登录信息');
  }





  /// 释放资源
  void dispose() {
    _client.close();
  }
}
