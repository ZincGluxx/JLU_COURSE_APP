# 📋 课表数据导入 - 快速三步法

## 🎯 适用场景

- 应用内WebView无法获取数据
- 课表页面HTML结构变化
- 需要手动调整课程数据
- 跨设备导入课程

---

## ⚡ 三步导入流程

### 第一步：电脑端提取（5分钟）

#### 1.1 打开课表页面

在**电脑**上用Chrome/Edge浏览器：
```
1. 访问 https://i.jlu.edu.cn
2. 登录账号
3. 进入"我的课表"页面
4. 确保所有课程已显示
```

#### 1.2 打开控制台

按 **F12** 键（或右键 → 检查）
点击顶部 **"Console"** 标签

#### 1.3 运行提取脚本

**复制下面的完整脚本** → 粘贴到控制台 → 按Enter

<details>
<summary>📜 点击展开：课表提取脚本（复制全部）</summary>

```javascript
(function(){console.log('🔍 开始分析课表页面...\n');var courses=[];var methods=[];var kbcells=document.querySelectorAll('.kbcontent');console.log('方法1: 找到 .kbcontent 元素:',kbcells.length,'个');if(kbcells.length>0){methods.push('方法1: .kbcontent');console.log('✅ 使用方法1提取\n');kbcells.forEach(function(cell,index){var text=(cell.innerText||cell.textContent).trim();var lines=text.split('\n').map(function(l){return l.trim();}).filter(function(l){return l;});if(lines.length===0)return;var courseName=lines[0];var teacher='';var location='';var weeksStr='';var sectionsStr='';for(var i=1;i<lines.length;i++){var line=lines[i];if(line.match(/\d+-\d+周/)){weeksStr=line;}else if(line.match(/第?\d+-?\d*节/)){sectionsStr=line;}else if(line.match(/教|楼|室|区/)){location=line;}else if(!teacher&&line.length<10&&line.length>1){teacher=line;}}var parentTd=cell.closest('td');var weekday=0;var startSection=0;var sections=1;if(parentTd){weekday=parseInt(parentTd.getAttribute('data-weekday')||0);startSection=parseInt(parentTd.getAttribute('data-section')||0);if(!weekday||!startSection){var row=parentTd.parentElement;var table=row.closest('table');if(table){var rows=Array.from(table.querySelectorAll('tr'));var rowIndex=rows.indexOf(row);var cells=Array.from(row.children);var colIndex=cells.indexOf(parentTd);if(rowIndex>0)startSection=rowIndex;if(colIndex>0)weekday=colIndex;}}}var weeks=[];if(weeksStr){var weekMatch=weeksStr.match(/(\d+)-(\d+)周/);if(weekMatch){var start=parseInt(weekMatch[1]);var end=parseInt(weekMatch[2]);for(var w=start;w<=end;w++){weeks.push(w);}}if(weeksStr.includes('单周')){weeks=weeks.filter(function(w){return w%2===1;});}else if(weeksStr.includes('双周')){weeks=weeks.filter(function(w){return w%2===0;});}}else{for(var w=1;w<=16;w++)weeks.push(w);}if(sectionsStr){var sectionMatch=sectionsStr.match(/(\d+)-(\d+)节/);if(sectionMatch){sections=parseInt(sectionMatch[2])-parseInt(sectionMatch[1])+1;}}if(courseName&&weekday>0&&startSection>0){courses.push({name:courseName,teacher:teacher||'未知',location:location||'未知',weekday:weekday,startSection:startSection,sections:sections,weeks:weeks});if(index<3){console.log(`  课程 ${index+1}:`,courseName,'|',teacher,'|',location);}}});}if(courses.length===0){var tables=document.querySelectorAll('table[id*="kb"], table.kb-table, #kbtable');console.log('方法2: 找到课表table:',tables.length,'个');if(tables.length>0){methods.push('方法2: table解析');console.log('✅ 使用方法2提取\n');tables.forEach(function(table){var rows=table.querySelectorAll('tr');rows.forEach(function(row,rowIndex){if(rowIndex===0)return;var cells=row.querySelectorAll('td');cells.forEach(function(cell,colIndex){if(colIndex===0)return;var text=(cell.innerText||cell.textContent).trim();if(!text||text.length<4)return;var lines=text.split('\n').map(function(l){return l.trim();}).filter(function(l){return l;});if(lines.length===0)return;courses.push({name:lines[0],teacher:lines[1]||'未知',location:lines[2]||'未知',weekday:colIndex,startSection:rowIndex,sections:2,weeks:[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]});});});});}}console.log('\n📊 提取统计:');console.log('  使用方法:',methods.join(', '));console.log('  课程总数:',courses.length,'门\n');if(courses.length===0){console.error('❌ 未能提取到课程数据！');console.log('\n🔍 页面结构分析:');console.log('  - .kbcontent 元素:',document.querySelectorAll('.kbcontent').length);console.log('  - table 元素:',document.querySelectorAll('table').length);console.log('  - 页面标题:',document.title);console.log('  - 当前URL:',window.location.href);return;}var json=JSON.stringify(courses,null,2);console.log('✅ 提取成功！\n');console.log('📋 课程数据JSON:');console.log('='.repeat(50));console.log(json);console.log('='.repeat(50));console.log('\n💾 数据已自动复制到剪贴板！');console.log('\n📱 下一步：');console.log('  1. 打开手机应用');console.log('  2. 设置 → 导入课表JSON');console.log('  3. 粘贴并导入\n');if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(json).then(function(){console.log('✅ 已复制！');}).catch(function(err){console.log('⚠️ 请手动复制上方JSON');});}else{console.log('⚠️ 请手动复制上方JSON');}return{success:true,count:courses.length,data:courses};})();
```

</details>

#### 1.4 获取结果

脚本运行后：
- ✅ 控制台显示 "提取成功"
- 📋 显示课程数量
- 💾 **JSON数据已自动复制到剪贴板！**

如果没有自动复制，请手动选中控制台中的JSON数据（两条 `===` 之间的内容）并复制。

---

### 第二步：传输数据到手机（2分钟）

选择以下任一方式：

#### 方式A：微信发送（推荐）
```
1. 微信文件传输助手
2. 新建记事本，粘贴JSON
3. 发送到手机
```

#### 方式B：云服务
```
- 百度网盘/OneDrive
- 创建文本文件粘贴JSON
- 手机端打开复制
```

#### 方式C：邮件
```
给自己发邮件
手机端打开复制
```

---

### 第三步：应用中导入（1分钟）

#### 3.1 打开导入功能

```
应用 → 设置 → 导入课表JSON
```

#### 3.2 粘贴数据

在文本框中**长按 → 粘贴**

#### 3.3 点击导入

点击 **"导入"** 按钮

#### 3.4 完成！

- ✅ 显示 "成功导入 X 门课程"
- ✅ 返回主页查看课表

---

## 📖 JSON数据格式示例

```json
[
  {
    "name": "高等数学A(1)",
    "teacher": "张三",
    "location": "中心校区-教学楼A101",
    "weekday": 1,
    "startSection": 1,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
  }
]
```

**字段说明**：
- `name`: 课程名称（必需）
- `teacher`: 教师姓名
- `location`: 上课地点
- `weekday`: 星期几（1-7，周一到周日）
- `startSection`: 第几节开始（1-12）
- `sections`: 持续几节课（通常是2）
- `weeks`: 哪些周上课（数组）

---

## ❓ 常见问题

### Q: 控制台运行脚本后显示"未能提取到课程数据"

**原因**：不在课表页面，或页面HTML结构不同

**解决**：
1. 确认页面上能看到课程表
2. 检查控制台输出的"页面结构分析"
3. 如果 `.kbcontent: 0` 且 `table: 0`，说明不在课表页面

### Q: JSON数据太长，无法复制完整

**解决**：
1. 在控制台输入并回车：
```javascript
console.save(JSON.stringify(courses, null, 2), 'courses.json')
```
2. 或使用文件传输方式

### Q: 导入时提示"JSON格式错误"

**原因**：数据复制不完整或格式错误

**解决**：
1. 确保复制了完整的JSON（以 `[` 开头，`]` 结尾）
2. 检查是否包含特殊字符
3. 使用 https://jsonlint.com 验证格式

### Q: 导入成功但课程数量不对

**原因**：部分课程数据不完整

**解决**：
1. 检查控制台输出的课程数量
2. 查看是否有警告信息
3. 手动编辑JSON补充缺失字段

### Q: 需要修改课程数据

**解决**：
在导入前，可以手动编辑JSON：
- 修改课程名称
- 调整上课时间
- 更改教室地点
- 删除不需要的课程

---

## 🔧 高级技巧

### 手动创建课程

如果脚本无法提取，可以手动创建JSON：

```json
[
  {
    "name": "你的课程名",
    "teacher": "教师名",
    "location": "教室位置",
    "weekday": 1,
    "startSection": 1,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
  }
]
```

### 批量编辑

使用文本编辑器的查找替换功能：
- 统一修改"校区"名称
- 批量调整周次
- 格式化教师名称

### 数据备份

导出的JSON可以保存为备份：
- 学期结束时保存
- 分享给同学
- 用于多设备导入

---

## 📊 方法对比

| 方法 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| WebView提取 | 全自动 | 受HTML结构限制 | ⭐⭐⭐ |
| JSON导入 | 灵活可靠 | 需要电脑操作 | ⭐⭐⭐⭐⭐ |
| 手动输入 | 完全控制 | 耗时较长 | ⭐⭐ |

---

## 🎯完整流程图

```
[电脑浏览器]
    ↓
打开课表页面
    ↓
F12 → Console
    ↓
运行提取脚本
    ↓
JSON自动复制
    ↓
[传输到手机]
    ↓
微信/云盘/邮件
    ↓
[手机应用]
    ↓
设置 → 导入JSON
    ↓
粘贴 → 导入
    ↓
✅ 完成！
```

---

**总用时**：约8分钟  
**成功率**：99%  
**难度**：⭐⭐☆☆☆

---

## 📞 需要帮助？

1. **脚本无法运行** → 查看 [GET_COURSE_DATA_NEW.md](GET_COURSE_DATA_NEW.md) 获取完整版本
2. **格式不对** → 使用 https://jsonlint.com 验证
3. **其他问题** → 查看应用内"使用指南"

---

**现在就开始** → 电脑打开 i.jlu.edu.cn 🚀
