# 吉林大学金智教务系统 API 对接指南

## 系统信息

- **教务系统**: 金智教务系统
- **课程表地址**: https://iedu.jlu.edu.cn/jwapp/sys/wdkb/*default/index.do?EMAP_LANG=zh#/xskcb
- **系统特点**: 需要统一身份认证登录

## 爬取方案

### 方案一：使用 HTTP 请求（推荐）

金智教务系统采用前后端分离架构，可以通过抓包分析 API 接口。

#### 步骤 1: 抓取真实 API 接口

1. 打开浏览器开发者工具（F12）
2. 登录教务系统: https://iedu.jlu.edu.cn/
3. 进入课程表页面
4. 在 Network 标签中查找 XHR/Fetch 请求
5. 找到课程表数据的 API 接口

**常见的金智教务 API 端点**:
- 登录: `/jwapp/sys/emapfunauth/pages/funauth/loginAuth.do`
- 课程表: `/jwapp/sys/wdkb/modules/xskcb/xskcb.do`
- 成绩: `/jwapp/sys/cjcx/modules/cjcx/xscjcx.do`
- 个人信息: `/jwapp/sys/emaphome/portal/getGrkm.do`

#### 步骤 2: 分析请求格式

记录以下信息：
- 请求方法（GET/POST）
- 请求头（Headers），特别是：
  - `Cookie`
  - `Authorization`
  - `X-Requested-With`
  - `Content-Type`
- 请求参数
- 响应数据格式

#### 步骤 3: 实现登录流程

```dart
// 典型的金智教务登录流程
class JluApiService {
  static const String baseUrl = 'https://iedu.jlu.edu.cn';
  final http.Client _client = http.Client();
  String? _cookie;
  String? _token;
  
  // 1. 统一身份认证登录
  Future<bool> login(String username, String password) async {
    try {
      // 第一步：访问登录页获取初始cookie
      final loginPageResponse = await _client.get(
        Uri.parse('$baseUrl/jwapp/sys/emapfunauth/pages/funauth/loginAuth.do'),
      );
      
      // 提取cookie
      _extractCookie(loginPageResponse.headers);
      
      // 第二步：提交登录表单
      final loginResponse = await _client.post(
        Uri.parse('$baseUrl/jwapp/sys/emapfunauth/casValidate.do'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _cookie ?? '',
        },
        body: {
          'username': username,
          'password': password,
        },
      );
      
      // 验证登录是否成功
      return loginResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  void _extractCookie(Map<String, String> headers) {
    if (headers.containsKey('set-cookie')) {
      _cookie = headers['set-cookie']!.split(';')[0];
    }
  }
}
```

### 方案二：使用 WebView（备选）

如果 API 接口难以分析或有复杂的加密，可以使用 WebView 自动化：

1. 在 Flutter 中嵌入 WebView
2. 自动填充用户名密码登录
3. 登录后通过 JavaScript 注入获取页面数据

需要添加依赖：
```yaml
dependencies:
  webview_flutter: ^4.4.0
```

## 实现示例

### 完整的 API 服务实现

见 `lib/services/jlu_api_service.dart`

### 使用 Python 脚本辅助抓包（可选）

如果你更熟悉 Python，可以先用 Python 验证 API：

```python
import requests
from bs4 import BeautifulSoup

class JluSpider:
    def __init__(self):
        self.session = requests.Session()
        self.base_url = 'https://iedu.jlu.edu.cn'
    
    def login(self, username, password):
        # 实现登录逻辑
        login_url = f'{self.base_url}/jwapp/sys/emapfunauth/casValidate.do'
        data = {
            'username': username,
            'password': password
        }
        response = self.session.post(login_url, data=data)
        return response.status_code == 200
    
    def get_courses(self):
        # 获取课程表
        course_url = f'{self.base_url}/jwapp/sys/wdkb/modules/xskcb/xskcb.do'
        response = self.session.post(course_url, json={
            'XNXQDM': '2024-2025-1'  # 学年学期代码
        })
        return response.json()

# 使用示例
spider = JluSpider()
if spider.login('学号', '密码'):
    courses = spider.get_courses()
    print(courses)
```

## 数据解析

### 课程表数据示例

金智教务系统返回的课程数据格式通常为：

```json
{
  "code": "0",
  "msg": "成功",
  "data": [
    {
      "KCM": "高等数学",           // 课程名
      "SKJS": "张教授",            // 授课教师
      "JASMC": "东荣大厦A201",     // 教室名称
      "SKXQ": "1",                 // 星期（1-7）
      "KSJC": "1",                 // 开始节次
      "JSJC": "2",                 // 结束节次
      "KKZC": "1-16",              // 开课周次
      "KCXZMC": "必修"             // 课程性质
    }
  ]
}
```

### 成绩数据示例

```json
{
  "code": "0",
  "data": [
    {
      "KCM": "高等数学",
      "XF": "5",                 // 学分
      "ZCJ": "92",               // 总成绩
      "JD": "4.2",               // 绩点
      "KCXZMC": "必修",
      "XNXQDM": "2024-2025-1"    // 学年学期
    }
  ]
}
```

## 注意事项

### 1. 安全性

- **不要在代码中硬编码密码**
- 使用安全存储（如 flutter_secure_storage）保存凭证
- 考虑使用加密传输

### 2. 合法性

- 仅供个人学习使用
- 不要频繁请求导致服务器压力
- 遵守学校相关规定

### 3. 验证码处理

如果遇到验证码：
- 方案1: 使用 OCR 识别（如 tesseract）
- 方案2: 使用第三方验证码识别服务
- 方案3: 使用 WebView 让用户手动输入

### 4. 请求限制

- 添加请求间隔（建议 1-2 秒）
- 处理会话超时，自动重新登录
- 实现请求重试机制

## 调试技巧

### 1. 使用 Postman 测试 API

1. 从浏览器复制 Cookie
2. 在 Postman 中模拟请求
3. 验证接口可用性
4. 导出为代码

### 2. Charles/Fiddler 抓包

- 设置代理抓取 HTTPS 请求
- 查看完整的请求和响应
- 分析加密参数的生成逻辑

### 3. 浏览器开发者工具

- Copy as cURL: 复制请求为 curl 命令
- Copy as fetch: 复制为 JavaScript 代码
- 查看请求的 Initiator 了解调用链

## 下一步

1. 按照本指南抓取真实 API 接口
2. 更新 `lib/services/jlu_api_service.dart`
3. 测试登录和数据获取功能
4. 根据实际数据格式调整模型

## 获取帮助

如果在对接过程中遇到问题：
1. 检查网络请求的完整过程
2. 对比浏览器和代码中的请求差异
3. 查看服务器返回的错误信息
4. 考虑是否有 CSRF Token 或其他安全机制

---

**重要提示**: 由于教务系统可能会更新，具体的 API 接口需要通过实际抓包获取。本文档提供的是通用方案和示例。
