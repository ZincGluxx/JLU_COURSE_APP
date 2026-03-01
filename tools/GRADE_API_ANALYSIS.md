# 成绩查询 API 分析报告

## HAR 文件来源
- 文件: `tools/cj1.har`
- 抓取位置: 吉林大学金智教务系统成绩查询页面
- Base URL: `https://iedu.jlu.edu.cn`

## 核心 API 端点

### 1. 学生成绩查询 (主接口)
**端点**: `/jwapp/sys/cjcx/modules/cjcx/xscjcx.do`  
**方法**: POST  
**Content-Type**: `application/x-www-form-urlencoded`  
**响应大小**: 11,772 bytes (分页) / 117,788 bytes (完整)

**请求参数**:
```
querySetting: [
  {
    "name": "XNXQDM",
    "value": "2025-2026-1,2025-2026-2",  // 学期代码，逗号分隔多个学期
    "linkOpt": "and",
    "builder": "m_value_equal"
  },
  {
    "name": "SFYX",
    "caption": "是否有效",
    "linkOpt": "AND",
    "builderList": "cbl_m_List",
    "builder": "m_value_equal",
    "value": "1",                         // 1=是, 0=否
    "value_display": "是"
  },
  {
    "name": "SHOWMAXCJ",
    "caption": "显示最高成绩",
    "linkOpt": "AND",
    "builderList": "cbl_m_List",
    "builder": "m_value_equal",
    "value": "0",                         // 1=是, 0=否
    "value_display": "否"
  }
]
*order: -XNXQDM,-KCH,-KXH                // 排序: 学期降序,课程号降序,课序号降序
pageSize: 20                             // 每页数量
pageNumber: 1                            // 当前页码
```

**实际抓包示例**:
```
POST https://iedu.jlu.edu.cn/jwapp/sys/cjcx/modules/cjcx/xscjcx.do
querySetting=%5B%7B%22name%22%3A%22XNXQDM%22%2C%22value%22%3A%222025-2026-1%2C2025-2026-2%22...
*order=-XNXQDM,-KCH,-KXH
pageSize=20
pageNumber=1
```

---

### 2. 检查成绩查询是否开放
**端点**: `/jwapp/sys/cjcx/modules/cjcx/cxcjcxsfkf.do`  
**方法**: POST  
**响应大小**: 155 bytes

**说明**: 检查系统是否允许查询成绩（可能在某些时间段关闭）

---

### 3. 获取可查询学期列表
**端点**: `/jwapp/sys/cjcx/modules/cjcx/cxdqxnxqhsygxnxq.do`  
**方法**: POST  
**响应大小**: 542 bytes

**说明**: 返回当前学期和历史可查询的所有学期

**响应格式** (推测):
```json
{
  "datas": {
    "cxdqxnxqhsygxnxq": {
      "rows": [
        {"XN": "2025-2026", "XQ": "2", "XNXQDM": "2025-2026-2"},
        {"XN": "2025-2026", "XQ": "1", "XNXQDM": "2025-2026-1"},
        ...
      ]
    }
  }
}
```

---

### 4. 检查是否为伪成绩时间段
**端点**: `/jwapp/sys/cjcx/modules/cjcx/cxsfwfcsj.do`  
**方法**: POST  
**响应大小**: 164 bytes

**说明**: 检查当前是否在"伪成绩"公示期（考试后正式成绩公布前）

---

### 5. 获取系统参数
**端点**: `/jwapp/sys/cjcx/modules/cjcx/cxxtcs.do`  
**方法**: POST  
**请求参数**:
```
CSDM: CJ
ZCSDM: NFCKFXCJ
```
**响应大小**: 556 bytes

**说明**: 获取成绩查询相关的系统配置参数

---

## 代码集成

### 已实现的方法

#### 1. `getGrades()` - 查询成绩
```dart
Future<List<Grade>> getGrades({
  List<String>? semesters,      // 学期列表，如 ["2025-2026-1", "2025-2026-2"]
  bool showMaxGrade = false,    // 是否显示最高成绩
  int pageSize = 100,           // 每页数量
  int pageNumber = 1,           // 页码
})
```

**使用示例**:
```dart
// 查询当前学期成绩
final grades = await apiService.getGrades(
  semesters: ['2025-2026-2'],
);

// 查询所有学期成绩
final allGrades = await apiService.getGrades();

// 查询指定学期并显示最高成绩
final maxGrades = await apiService.getGrades(
  semesters: ['2024-2025-1', '2024-2025-2'],
  showMaxGrade: true,
);
```

#### 2. `checkGradeQueryOpen()` - 检查开放状态
```dart
Future<bool> checkGradeQueryOpen()
```

**使用示例**:
```dart
final isOpen = await apiService.checkGradeQueryOpen();
if (!isOpen) {
  print('当前时间段不允许查询成绩');
}
```

#### 3. `getAvailableSemesters()` - 获取学期列表
```dart
Future<List<Map<String, String>>> getAvailableSemesters()
```

**使用示例**:
```dart
final semesters = await apiService.getAvailableSemesters();
for (var semester in semesters) {
  print('学年: ${semester['XN']}, 学期: ${semester['XQ']}, 代码: ${semester['XNXQDM']}');
}
```

---

## 关键发现

### 1. 请求格式特点
- **Content-Type**: 必须是 `application/x-www-form-urlencoded`，不是 JSON
- **参数编码**: querySetting 需要先 JSON.encode 再 URL encode
- **分页支持**: 通过 pageSize/pageNumber 控制
- **多学期查询**: XNXQDM 使用逗号分隔多个学期代码

### 2. 学期代码格式
- 格式: `{学年}-{学期序号}`
- 示例: 
  - `2025-2026-1` = 2025-2026学年 第1学期 (秋季)
  - `2025-2026-2` = 2025-2026学年 第2学期 (春季)
  - `2025-2026-3` = 2025-2026学年 第3学期 (暑期，如有)

### 3. 响应数据路径
可能的 JSON 路径:
- `data.datas.xscjcx.rows` (主路径)
- `data.data` (备用)
- `data.rows` (备用)

### 4. 安全机制
- 需要有效的登录 Cookie
- 需要正确的 Referer 头
- 请求需要 X-Requested-With: XMLHttpRequest

---

## 与课程 API 对比

| 特性 | 课程 API | 成绩 API |
|------|---------|---------|
| Content-Type | `x-www-form-urlencoded` | `x-www-form-urlencoded` |
| 参数格式 | 简单键值对 | 复杂 JSON 结构 |
| 分页支持 | 无 | 有 (pageSize/pageNumber) |
| 多学期查询 | 单个学期 | 支持多学期逗号分隔 |
| 响应大小 | ~16KB | ~11KB (分页) / ~117KB (完整) |

---

## 测试建议

### 1. 基础测试
```dart
// 1. 检查是否开放
final isOpen = await apiService.checkGradeQueryOpen();

// 2. 获取学期列表
final semesters = await apiService.getAvailableSemesters();

// 3. 查询最新学期成绩
final latestGrades = await apiService.getGrades(
  semesters: [semesters.first['XNXQDM']!],
  pageSize: 20,
);
```

### 2. 边界测试
- 空学期列表（查询所有）
- 单学期查询
- 多学期查询 (2个+)
- 大页面数 (pageSize: 500)
- 无效学期代码

### 3. 错误处理
- 未登录状态
- Cookie 过期
- 服务器返回错误
- 网络超时

---

## 待验证事项

由于 HAR 文件中 `response.content.text` 为空，以下内容需要实际测试验证:

1. **响应 JSON 结构**: 实际字段名称和嵌套层级
2. **成绩字段映射**: 
   - 课程名称字段: `KCMC`?
   - 成绩字段: `CJ`? `ZCJ`?
   - 学分字段: `XF`?
   - 绩点字段: `JD`?
3. **错误响应格式**: 当查询失败时的返回结构
4. **开放状态字段**: `SFKF` 字段的具体含义
5. **分页信息**: 总记录数、总页数等元数据

---

## 下一步行动

1. ✅ 集成成绩查询 API 到 `JluApiService`
2. ⏳ 实际测试验证响应格式
3. ⏳ 根据真实响应调整 `_parseGrade()` 方法
4. ⏳ 在 UI 中添加成绩查询功能
5. ⏳ 实现成绩统计（GPA计算、学分汇总等）

---

## 文件变更记录

### `lib/services/jlu_api_service.dart`
- ✅ 添加成绩相关路径常量:
  - `gradePath`: 成绩查询主接口
  - `gradeCheckOpenPath`: 检查开放状态
  - `gradeSemesterPath`: 获取学期列表
- ✅ 更新 `getGrades()` 方法使用 HAR 抓包的真实参数
- ✅ 添加 `checkGradeQueryOpen()` 方法
- ✅ 添加 `getAvailableSemesters()` 方法
- ✅ 改进错误处理和日志输出

---

*分析时间: 2026-03-01*  
*HAR 来源: 吉林大学金智教务系统*  
*状态: 已集成，待测试验证*
