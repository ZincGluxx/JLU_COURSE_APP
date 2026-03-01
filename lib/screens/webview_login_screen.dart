import 'package:flutter/material.dart';
import '../widgets/webview_login.dart';
import '../services/jlu_api_service.dart';

/// WebView登录页面
/// 
/// 使用WebView加载CAS认证页面，用户完成登录后自动提取Cookie
class WebViewLoginScreen extends StatelessWidget {
  const WebViewLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewLogin(
      serviceUrl: 'https://iedu.jlu.edu.cn/jwapp/sys/',
      onCookiesExtracted: (cookies) async {
        // Cookie提取成功，设置到API服务中
        final apiService = JluApiService();
        final success = await apiService.setLoginCookies(cookies);
        
        if (success && context.mounted) {
          // 登录成功，返回主页
          Navigator.of(context).pop(true);
        } else if (context.mounted) {
          // 设置Cookie失败
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登录信息设置失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
