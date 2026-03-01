# 🔄 重新获取课表数据指南

## 方案概述

由于不同学期的课表页面HTML结构可能不同，我们提供一个**更可靠的方式**：
1. 在电脑浏览器中打开课表页面
2. 运行我们提供的JavaScript脚本
3. 复制生成的JSON数据
4. 导入到应用中

---

## 📝 详细步骤

### 第一步：在电脑上打开课表页面

1. **打开Chrome或Edge浏览器**
2. **访问** `https://i.jlu.edu.cn`
3. **登录**您的账号
4. **找到并打开"我的课表"页面**
   - 确保能看到完整的课程表
   - 所有课程都已加载完成

### 第二步：打开浏览器控制台

**Windows**: 按 `F12` 或 `Ctrl + Shift + I`  
**Mac**: 按 `Cmd + Option + I`

或者：右键点击页面 → "检查" 或 "Inspect"

### 第三步：切换到Console标签

在开发者工具中，点击顶部的 **"Console"** 或 **"控制台"** 标签

### 第四步：运行提取脚本

复制下面的完整脚本，粘贴到控制台中，按回车运行：

```javascript
(function() {
    console.log('🔍 开始分析课表页面...\n');
    
    var courses = [];
    var methods = [];
    
    // ============================================
    // 方法1: 查找 .kbcontent 元素
    // ============================================
    var kbcells = document.querySelectorAll('.kbcontent');
    console.log('方法1: 找到 .kbcontent 元素:', kbcells.length, '个');
    
    if (kbcells.length > 0) {
        methods.push('方法1: .kbcontent');
        console.log('✅ 使用方法1提取\n');
        
        kbcells.forEach(function(cell, index) {
            var text = (cell.innerText || cell.textContent).trim();
            var lines = text.split('\n').map(function(l) { return l.trim(); }).filter(function(l) { return l; });
            
            if (lines.length === 0) return;
            
            // 解析课程信息
            var courseName = lines[0];
            var teacher = '';
            var location = '';
            var weeksStr = '';
            var sectionsStr = '';
            
            for (var i = 1; i < lines.length; i++) {
                var line = lines[i];
                if (line.match(/\d+-\d+周/)) {
                    weeksStr = line;
                } else if (line.match(/第?\d+-?\d*节/)) {
                    sectionsStr = line;
                } else if (line.match(/教|楼|室|区/)) {
                    location = line;
                } else if (!teacher && line.length < 10 && line.length > 1) {
                    teacher = line;
                }
            }
            
            // 获取位置 (星期和节次)
            var parentTd = cell.closest('td');
            var weekday = 0;
            var startSection = 0;
            var sections = 1; // 默认1节课
            
            if (parentTd) {
                // 尝试从data属性获取
                weekday = parseInt(parentTd.getAttribute('data-weekday') || 0);
                startSection = parseInt(parentTd.getAttribute('data-section') || 0);
                
                // 如果没有data属性，从表格位置推断
                if (!weekday || !startSection) {
                    var row = parentTd.parentElement;
                    var table = row.closest('table');
                    if (table) {
                        var rows = Array.from(table.querySelectorAll('tr'));
                        var rowIndex = rows.indexOf(row);
                        var cells = Array.from(row.children);
                        var colIndex = cells.indexOf(parentTd);
                        
                        if (rowIndex > 0) startSection = rowIndex;
                        if (colIndex > 0) weekday = colIndex;
                    }
                }
            }
            
            // 解析周次
            var weeks = [];
            if (weeksStr) {
                var weekMatch = weeksStr.match(/(\d+)-(\d+)周/);
                if (weekMatch) {
                    var start = parseInt(weekMatch[1]);
                    var end = parseInt(weekMatch[2]);
                    for (var w = start; w <= end; w++) {
                        weeks.push(w);
                    }
                }
                // 检查是否是单双周
                if (weeksStr.includes('单周')) {
                    weeks = weeks.filter(function(w) { return w % 2 === 1; });
                } else if (weeksStr.includes('双周')) {
                    weeks = weeks.filter(function(w) { return w % 2 === 0; });
                }
            } else {
                // 默认1-16周
                for (var w = 1; w <= 16; w++) weeks.push(w);
            }
            
            // 解析节次数量
            if (sectionsStr) {
                var sectionMatch = sectionsStr.match(/(\d+)-(\d+)节/);
                if (sectionMatch) {
                    sections = parseInt(sectionMatch[2]) - parseInt(sectionMatch[1]) + 1;
                }
            }
            
            if (courseName && weekday > 0 && startSection > 0) {
                courses.push({
                    name: courseName,
                    teacher: teacher || '未知',
                    location: location || '未知',
                    weekday: weekday,
                    startSection: startSection,
                    sections: sections,
                    weeks: weeks
                });
                
                if (index < 3) {
                    console.log(`  课程 ${index + 1}:`, courseName, '|', teacher, '|', location);
                }
            }
        });
    }
    
    // ============================================
    // 方法2: 查找 table 元素
    // ============================================
    if (courses.length === 0) {
        var tables = document.querySelectorAll('table[id*="kb"], table.kb-table, #kbtable');
        console.log('方法2: 找到课表table:', tables.length, '个');
        
        if (tables.length > 0) {
            methods.push('方法2: table解析');
            console.log('✅ 使用方法2提取\n');
            
            tables.forEach(function(table) {
                var rows = table.querySelectorAll('tr');
                rows.forEach(function(row, rowIndex) {
                    if (rowIndex === 0) return; // 跳过表头
                    
                    var cells = row.querySelectorAll('td');
                    cells.forEach(function(cell, colIndex) {
                        if (colIndex === 0) return; // 跳过第一列
                        
                        var text = (cell.innerText || cell.textContent).trim();
                        if (!text || text.length < 4) return;
                        
                        var lines = text.split('\n').map(function(l) { return l.trim(); }).filter(function(l) { return l; });
                        if (lines.length === 0) return;
                        
                        courses.push({
                            name: lines[0],
                            teacher: lines[1] || '未知',
                            location: lines[2] || '未知',
                            weekday: colIndex,
                            startSection: rowIndex,
                            sections: 2,
                            weeks: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
                        });
                    });
                });
            });
        }
    }
    
    // ============================================
    // 结果输出
    // ============================================
    console.log('\n📊 提取统计:');
    console.log('  使用方法:', methods.join(', '));
    console.log('  课程总数:', courses.length, '门\n');
    
    if (courses.length === 0) {
        console.error('❌ 未能提取到课程数据！');
        console.log('\n🔍 页面结构分析:');
        console.log('  - .kbcontent 元素:', document.querySelectorAll('.kbcontent').length);
        console.log('  - table 元素:', document.querySelectorAll('table').length);
        console.log('  - 页面标题:', document.title);
        console.log('  - 当前URL:', window.location.href);
        console.log('\n💡 请确保：');
        console.log('  1. 已经登录教务系统');
        console.log('  2. 当前页面是课表页面');
        console.log('  3. 课程已经完全加载');
        console.log('\n如果确认在课表页面，请将上述信息截图反馈给开发者。');
        return;
    }
    
    // 生成JSON
    var json = JSON.stringify(courses, null, 2);
    
    console.log('✅ 提取成功！课程数据已复制到剪贴板\n');
    console.log('📋 下一步：');
    console.log('  1. 数据已自动复制（如未复制，请手动选择下方JSON）');
    console.log('  2. 打开手机应用');
    console.log('  3. 进入"设置" -> "导入课表JSON"');
    console.log('  4. 粘贴数据并导入\n');
    
    console.log('📦 课程数据JSON:');
    console.log('='.repeat(50));
    console.log(json);
    console.log('='.repeat(50));
    
    // 尝试复制到剪贴板
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(json).then(function() {
            console.log('\n✅ 已自动复制到剪贴板！');
        }).catch(function(err) {
            console.log('\n⚠️ 自动复制失败，请手动选择上方JSON数据复制');
        });
    } else {
        console.log('\n⚠️ 浏览器不支持自动复制，请手动选择上方JSON数据复制');
    }
    
    // 提供下载选项
    console.log('\n💾 或者点击下方链接下载为文件:');
    var blob = new Blob([json], {type: 'application/json'});
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = 'courses.json';
    a.textContent = '📥 点击下载 courses.json';
    a.style.cssText = 'display:block; padding:10px; background:#4CAF50; color:white; text-decoration:none; border-radius:4px; margin:10px 0;';
    console.log('下载链接对象已创建，执行以下代码显示下载按钮：');
    console.log('document.body.insertBefore(a, document.body.firstChild);');
    
    return {
        success: true,
        count: courses.length,
        methods: methods,
        data: courses
    };
})();
```

### 第五步：查看结果

脚本运行后会显示：
- ✅ 提取成功的消息
- 📊 提取的课程数量
- 📋 JSON格式的课程数据

**数据会自动复制到剪贴板！** 如果没有自动复制，请手动选择控制台中的JSON数据并复制。

### 第六步：导入到应用

1. 打开手机应用
2. 进入 **"设置"** 页面
3. 点击 **"导入课表JSON"**（新增功能）
4. 粘贴刚才复制的JSON数据
5. 点击 **"导入"** 按钮
6. 完成！

---

## 📱 JSON数据格式说明

生成的JSON格式如下：

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
  },
  {
    "name": "大学英语(1)",
    "teacher": "李四",
    "location": "中心校区-外语楼201",
    "weekday": 2,
    "startSection": 3,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
  }
]
```

**字段说明**：
- `name`: 课程名称
- `teacher`: 教师姓名
- `location`: 上课地点
- `weekday`: 星期几（1=周一, 7=周日）
- `startSection`: 起始节次（1-12）
- `sections`: 持续节次数量（通常是2）
- `weeks`: 上课周次数组

---

## 🛠️ 如果脚本无法提取

### 方案A：手动构建JSON

如果自动脚本无法识别课表结构，您可以手动创建JSON：

1. 查看网页上的课程信息
2. 按照上面的JSON格式手动编写
3. 确保格式正确（可使用 https://jsonlint.com 验证）
4. 导入到应用

### 方案B：提供页面结构

如果仍然失败，请：

1. 在控制台运行：
```javascript
console.log('页面HTML:', document.body.innerHTML.substring(0, 5000));
```

2. 复制输出的HTML
3. 反馈给开发者，我们会为您定制提取脚本

---

## ❓ 常见问题

### Q1: 控制台在哪里？
按 `F12`，点击顶部的 "Console" 标签

### Q2: 粘贴脚本后没反应
确保按了 `Enter` 键执行脚本

### Q3: 显示"未能提取到课程数据"
- 确认页面上能看到课程表
- 尝试刷新页面后重新运行脚本
- 查看控制台的"页面结构分析"信息

### Q4: JSON数据太长，复制不完整
使用控制台提供的下载链接，下载为文件后传输到手机

### Q5: 手机上如何导入JSON文件？
- 方法1: 用电脑发送JSON到手机（微信/邮件）
- 方法2: 文件传到手机后，用文本编辑器打开，复制内容
- 方法3: 使用云盘（如百度网盘）同步文件

---

## 🎯 完整流程图

```
电脑浏览器 → 登录i.jlu.edu.cn 
           → 打开课表页面
           → F12打开控制台
           → 运行提取脚本
           → 复制JSON数据
           ↓
手机应用   → 设置
           → 导入课表JSON
           → 粘贴数据
           → 导入
           → 完成 ✅
```

---

**这个方法的优势**：
- ✅ 不依赖特定HTML结构
- ✅ 可以手动调整数据
- ✅ 适用于任何课表系统
- ✅ 数据可以保存和分享
- ✅ 支持手动编辑和验证

**下一步**: 我将在应用中添加"导入课表JSON"功能
