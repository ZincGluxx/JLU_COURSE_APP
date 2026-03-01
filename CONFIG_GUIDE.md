# 吉林大学课程表 App - 配置快速指南

## 🎯 目标
让你的应用能够从吉林大学金智教务系统获取真实的课程表和成绩数据。

## 📋 前置准备

- [ ] 已安装 Flutter 开发环境
- [ ] 拥有吉林大学教务系统账号
- [ ] 能够访问 https://iedu.jlu.edu.cn/

## 🚀 配置步骤

### 步骤 1: 测试登录（可选但推荐）

使用 Python 脚本快速验证 API：

```bash
# 安装 Python 依赖
pip install requests

# 编辑 tools/jlu_api_test.py，填入学号密码
# 然后运行
python tools/jlu_api_test.py
```

如果成功，会生成 `course_data.json` 和 `grade_data.json` 文件。

### 步骤 2: 浏览器抓包

1. **打开浏览器**（Chrome/Edge），按 F12

2. **切换到 Network 标签**

3. **登录教务系统**
   ```
   https://iedu.jlu.edu.cn/
   ```

4. **进入课程表页面**，筛选 XHR 请求

5. **找到关键接口**，记录以下信息：

   | 接口类型 | 可能的 URL 包含 | 请求方法 |
   |---------|----------------|---------|
   | 登录 | casValidate, login | POST |
   | 课程表 | wdkb, xskcb | POST |
   | 成绩 | cjcx, xscjcx | POST |

6. **右键点击请求 → Copy → Copy as cURL**

### 步骤 3: 更新代码配置

打开 `lib/services/jlu_api_service.dart`：

```dart
// 1. 更新 API 路径（根据你抓包的结果）
static const String loginPath = '/jwapp/sys/emapfunauth/casValidate.do';  // ← 改这里
static const String coursePath = '/jwapp/sys/wdkb/modules/xskcb/xskcb.do';  // ← 改这里
static const String gradePath = '/jwapp/sys/cjcx/modules/cjcx/xscjcx.do';   // ← 改这里

// 2. 更新字段映射（根据实际响应数据）
Course _parseCourse(Map<String, dynamic> json) {
  return Course(
    id: json['JXBH'] ?? '',           // ← 根据实际字段名修改
    name: json['KCM'] ?? '',          // ← 课程名字段
    teacher: json['SKJS'] ?? '',      // ← 教师字段
    location: json['JASMC'] ?? '',    // ← 教室字段
    // ... 以此类推
  );
}
```

### 步骤 4: 测试应用

1. **运行应用**
   ```bash
   flutter run
   ```

2. **尝试登录**
   - 打开应用 → 设置 → 点击"未登录"
   - 输入学号和密码
   - 观察控制台输出

3. **查看日志**
   - 如果登录失败，查看 console 输出的错误信息
   - 对比浏览器请求和应用请求的差异

### 步骤 5: 调试与优化

如果遇到问题：

**问题 1: 登录失败 401/403**
- 检查请求头是否完整
- 确认 Cookie 是否正确传递
- 对比浏览器中的请求

**问题 2: 数据解析错误**
- 打印响应数据: `print(response.body)`
- 查看实际字段名
- 更新 `_parseCourse` 方法

**问题 3: 验证码**
- 查看是否可以通过 User-Agent 绕过
- 考虑使用 WebView 方案

## 📊 字段对照参考

### 课程表常见字段

| 中文 | 金智系统可能的字段名 |
|-----|------------------|
| 课程ID | JXBH, KCH |
| 课程名 | KCM, KCMC |
| 教师 | SKJS, JSXM |
| 教室 | JASMC, JXCDMC |
| 星期 | SKXQ, XQ |
| 开始节次 | KSJC |
| 结束节次 | JSJC |
| 周次 | KKZC, ZC |

### 成绩常见字段

| 中文 | 金智系统可能的字段名 |
|-----|------------------|
| 课程ID | JXBH |
| 课程名 | KCM |
| 学分 | XF |
| 成绩 | ZCJ, CJ |
| 绩点 | JD |

## ✅ 完成检查清单

配置完成后，确认以下功能正常：

- [ ] 能够成功登录
- [ ] 课程表正确显示
- [ ] 成绩数据正确显示
- [ ] GPA 计算正确
- [ ] 课程详情显示完整
- [ ] 退出登录功能正常

## 📚 更多帮助

- [完整 API 对接指南](JLU_API_GUIDE.md)
- [详细爬虫教程](CRAWLER_USAGE.md)
- [工具脚本说明](tools/README.md)

## 💡 提示

1. **安全提醒**：不要将包含真实账号密码的代码提交到公开仓库
2. **测试账号**：建议使用测试账号进行开发
3. **请求频率**：不要频繁请求，避免给服务器造成压力
4. **持续维护**：教务系统可能更新，需要相应调整代码

## 🆘 获取帮助

如果配置过程中遇到问题：
1. 检查 console 输出的详细错误信息
2. 使用 Postman 验证 API 接口
3. 对比浏览器和应用的请求差异
4. 查看 `JLU_API_GUIDE.md` 中的故障排查部分

---

**祝你配置顺利！** 🎉
