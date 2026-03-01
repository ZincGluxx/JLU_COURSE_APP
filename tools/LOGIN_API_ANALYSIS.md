# JLU CAS登录API分析文档

## 一、概述

吉林大学使用CAS (Central Authentication Service) 统一认证系统进行登录。

- **CAS服务器**: `https://cas.jlu.edu.cn/tpass/`
- **业务系统**: `https://i.jlu.edu.cn/` (统一门户) 或 `https://iedu.jlu.edu.cn/` (教务系统)
- **认证协议**: CAS 3.0

## 二、完整登录流程

### 流程图

```
1. 访问业务系统
   ↓
2. 重定向到CAS登录页面 (带service参数)
   GET https://cas.jlu.edu.cn/tpass/login?service=https://i.jlu.edu.cn/up/view?m=up
   ↓
3. 从登录页面提取参数 (lt, execution, 公钥)
   ↓
4. RSA加密密码
   ↓
5. POST提交到CAS登录接口
   POST https://cas.jlu.edu.cn/tpass/login?service=...
   Body: rsa=加密后的密码&ul=用户名长度&pl=密码长度&lt=...&execution=...&_eventId=submit
   ↓
6. CAS返回302重定向 (带ticket)
   Location: https://i.jlu.edu.cn/up/view?m=up&ticket=ST-xxx-xxx-tpass
   ↓
7. 访问业务系统验证ticket
   GET https://i.jlu.edu.cn/up/view?m=up&ticket=ST-xxx
   ↓
8. 业务系统设置Cookie (MOD_AUTH_CAS, JSESSIONID等)
   ↓
9. 完成登录
```

### 详细步骤

#### Step 1: 获取登录页面

**请求:**
```http
GET https://cas.jlu.edu.cn/tpass/login?service=https://i.jlu.edu.cn/up/view?m=up HTTP/1.1
```

**响应:** HTML页面，包含以下关键信息：
- `<input name="lt" value="LT-xxxxx-xxx-tpass" />` - 登录票据
- `<input name="execution" value="e2s1" />` - 执行流程ID
- JavaScript中的RSA公钥 (用于加密密码)

#### Step 2: POST登录请求

**请求:**
```http
POST https://cas.jlu.edu.cn/tpass/login?service=https%3A%2F%2Fi.jlu.edu.cn%2Fup%2Fview%3Fm%3Dup HTTP/1.1
Content-Type: application/x-www-form-urlencoded

rsa=A68177429C4212363ACA056316D1AFC2AFFB8D93A9085506C5D513A353002D88897C0A2707AEA299ADB397F74E3DB9380B7B11165854C3E59550B4C597603C1F0703D78E67C3FB93FD4D4B97C026B87AD3E962ED7937FB4362133E31826DAE194425AAC6A4E47DDE5D3C8A08D0BE66BEEBFD5E49079E7ACFBF0FF064F5F1E7AA9668FE464C1DBD45&ul=9&pl=10&sl=0&lt=LT-13319901-dveKgXDgMHnlsjED9AmUcIcGTjEInU-tpass&execution=e2s1&_eventId=submit
```

**参数说明:**
| 参数 | 说明 | 示例值 |
|------|------|--------|
| `rsa` | RSA加密后的用户名+密码 | A68177429C42...1DBD45 (272字符) |
| `ul` | 用户名长度 | 9 |
| `pl` | 密码长度 | 10 |
| `sl` | Screen Lock状态？ | 0 |
| `lt` | 登录票据 (从页面获取) | LT-13319901-dveKgXDgMHnlsjED9AmUcIcGTjEInU-tpass |
| `execution` | 执行流程 (从页面获取) | e2s1 |
| `_eventId` | 事件ID | submit |

**响应:**
```http
HTTP/1.1 302 Found
Location: https://i.jlu.edu.cn/up/view?m=up&ticket=ST-7240493-TzFRIC7R64kfIY5scgC2-tpass
```

#### Step 3: 使用Ticket验证

**请求:**
```http
GET https://i.jlu.edu.cn/up/view?m=up&ticket=ST-7240493-TzFRIC7R64kfIY5scgC2-tpass HTTP/1.1
```

**响应:**
```http
HTTP/1.1 302 Found
Location: https://i.jlu.edu.cn/up/view?m=up
Set-Cookie: MOD_AUTH_CAS=...; Path=/; HttpOnly
Set-Cookie: JSESSIONID=...; Path=/up; HttpOnly
```

#### Step 4: 访问业务系统

**请求:**
```http
GET https://i.jlu.edu.cn/up/view?m=up HTTP/1.1
Cookie: MOD_AUTH_CAS=...; JSESSIONID=...
```

**响应:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
```

## 三、关键技术点

### 1. RSA加密

CAS登录使用RSA非对称加密来保护用户名和密码：

1. 从登录页面JavaScript中提取RSA公钥 (modulus和exponent)
2. 拼接字符串: `用户名 + 密码 + lt值`
3. 使用公钥加密该字符串
4. 将加密结果转换为十六进制字符串

**示例代码 (Dart):**
```dart
import 'package:pointycastle/export.dart';
import 'dart:typed_data';
import 'dart:convert';

String encryptPassword(String username, String password, String lt, String modulus, String exponent) {
  // 拼接明文
  String plainText = username + password + lt;
  
  // 解析公钥
  final publicKey = RSAPublicKey(
    BigInt.parse(modulus, radix: 16),
    BigInt.parse(exponent, radix: 16),
  );
  
  // RSA加密
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  
  final input = Uint8List.fromList(utf8.encode(plainText));
  final encrypted = encryptor.process(input);
  
  // 转换为十六进制
  return encrypted.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
}
```

### 2. Service参数

`service` 参数指定登录成功后要返回的业务系统URL：

- **统一门户**: `https://i.jlu.edu.cn/up/view?m=up`
- **教务系统**: `https://iedu.jlu.edu.cn/jwapp/sys/`

登录后CAS会重定向到 `service + &ticket=ST-xxx`

### 3. Cookie管理

登录成功后需要保存以下Cookie:

- `MOD_AUTH_CAS`: CAS认证Cookie
- `JSESSIONID`: 会话ID
- `route`: 路由Cookie (负载均衡)

这些Cookie在后续访问业务系统时必须携带。

## 四、教务系统登录适配

如果要直接登录到教务系统 (iedu.jlu.edu.cn)，需要：

1. **修改service参数:**
   ```
   https://cas.jlu.edu.cn/tpass/login?service=https://iedu.jlu.edu.cn/jwapp/sys/
   ```

2. **跟随重定向:**
   ```
   302 -> https://iedu.jlu.edu.cn/jwapp/sys/?ticket=ST-xxx
   302 -> https://iedu.jlu.edu.cn/jwapp/sys/
   200 -> 教务系统首页
   ```

3. **设置应用角色 (可选):**
   ```http
   POST https://iedu.jlu.edu.cn/jwapp/sys/jwpubapp/pub/setJwCommonAppRole.do
   Content-Type: application/x-www-form-urlencoded
   
   ROLEID=ef212c48c8f84be79acbd9d81b090f51
   ```

## 五、实现建议

### 方案一：完整CAS流程 (推荐)

实现完整的CAS客户端，包括：
- 获取登录页面并解析lt/execution/公钥
- RSA加密
- 提交登录
- 处理ticket验证
- Cookie管理

**优点:** 完全模拟浏览器行为，稳定可靠
**缺点:** 实现复杂，需要RSA加密库

### 方案二：使用WebView + Cookie提取

使用WebView让用户完成登录，然后提取Cookie：

```dart
// 监听导航
webViewController.setNavigationDelegate(
  NavigationDelegate(
    onPageFinished: (url) async {
      if (url.contains('i.jlu.edu.cn') || url.contains('iedu.jlu.edu.cn')) {
        // 提取Cookie
        final cookies = await cookieManager.getCookies(Uri.parse(url));
        // 保存Cookie供后续API调用使用
      }
    },
  ),
);
```

**优点:** 实现简单，无需处理加密
**缺点:** 依赖WebView，用户体验不如原生

### 方案三：混合方案

第一次使用WebView登录并保存Cookie，后续使用Cookie直接调用API。当Cookie过期时重新使用WebView登录。

## 六、已知问题

1. **RSA公钥提取**: 公钥在登录页面的JavaScript中，需要解析HTML/JS
2. **lt有效期**: lt值有时间限制，不能预先获取
3. **验证码**: 某些情况下可能需要输入验证码
4. **IP限制**: 频繁登录可能触发安全限制

## 七、测试步骤

1. 记录浏览器登录的完整网络请求
2. 提取关键参数 (lt, execution, 公钥)
3. 实现RSA加密
4. 模拟POST登录
5. 验证Cookie是否有效
6. 测试Cookie能否调用业务API

## 八、相关依赖

```yaml
dependencies:
  # HTTP请求
  http: ^1.2.0
  
  # Cookie管理
  cookie_jar: ^4.0.8
  
  # RSA加密
  pointycastle: ^3.9.1
  
  # HTML解析
  html: ^0.15.4
  
  # WebView (方案二)
  webview_flutter: ^4.7.0
```
