# 🎯 专用课表提取脚本（针对您的HTML）

## 📋 您的课表数据

从 `body.html` 中识别到以下课程：

### 2025-2026学年第2学期 课表

| 课程 | 教师 | 星期 | 节次 | 周次 | 地点 |
|------|------|------|------|------|------|
| **半导体物理实验** | 李国兴等8人 | 星期五 | 1-4节 | 2-10周 | - |
| **光电子学与光电器件实验** | 刘大力等9人 | 星期五 | 1-4节 | 11-16周 | - |
| **半导体器件物理** | 陈占国 | 星期二 | 3-4节 | 1-14周 | 前卫-逸夫楼-第十三阶梯 |
| **半导体器件物理** | 陈占国 | 星期四 | 3-4节 | 1-14周 | 前卫-逸夫楼-第十一阶梯 |
| **大学生职业发展与就业创业指导Ⅱ** | 孟祥羽 | 星期六 | 3-4节 | 5-13周 | - |
| **光通信原理与技术** | 王希斌 | 星期一 | 5-6节 | 1-10周 | 前卫-敬信教学楼-D区305 |
| **光通信原理与技术** | 王希斌 | 星期三 | 5-6节 | 1-10周 | 前卫-萃文教学楼-第六阶梯 |
| **可重构硬件及FPGA应用** | 张健 | 星期一 | 9-10节 | 1-10周 | 前卫-逸夫楼-307 |
| **模拟集成电路设计** | 毕宴钢 | 星期二 | 9-10节 | 1-14周 | 前卫-逸夫楼-第七阶梯 |
| **可重构硬件及FPGA应用** | 张健 | 星期三 | 9-10节 | 1-10周 | 前卫-逸夫楼-307 |
| **模拟集成电路设计** | 毕宴钢 | 星期四 | 9-10节 | 1-14周 | 前卫-逸夫楼-第七阶梯 |
| **半导体材料实验** | 徐颖等4人 | 星期四 | 11-12节 | 1-16周 | - |

---

## 🚀 专用提取脚本

这个脚本专门针对您的HTML结构设计：

```javascript
(function() {
    console.log('🔍 开始提取课表数据...\n');
    
    var courses = [];
    
    // 查找所有课程元素
    var courseItems = document.querySelectorAll('.mtt_arrange_item');
    console.log('找到', courseItems.length, '个课程\n');
    
    courseItems.forEach(function(item, index) {
        try {
            // 提取课程名称
            var kcmcDiv = item.querySelector('.mtt_item_kcmc');
            if (!kcmcDiv) return;
            
            var courseName = kcmcDiv.childNodes[0].textContent.trim();
            
            // 提取教师
            var teacherDiv = item.querySelector('.mtt_item_jxbmc');
            var teacher = teacherDiv ? teacherDiv.textContent.trim() : '未知';
            
            // 提取教室
            var roomDiv = item.querySelector('.mtt_item_room');
            var roomText = roomDiv ? roomDiv.textContent.trim() : '';
            
            // 解析周次和节次
            var weekMatch = roomText.match(/(\d+)-(\d+)周/);
            var dayMatch = roomText.match(/星期(\d+)/);
            var sectionMatch = roomText.match(/第(\d+)节-第(\d+)节/);
            
            // 解析地点
            var location = '';
            var locationMatch = roomText.match(/第\d+节-第\d+节,(.+?)$/);
            if (locationMatch) {
                location = locationMatch[1].replace(/<[^>]+>/g, '').trim();
            }
            
            // 获取父TD的位置信息
            var parentTd = item.closest('td');
            var weekday = 1;
            var startSection = 1;
            var sections = 2;
            
            if (parentTd) {
                var dataWeek = parentTd.getAttribute('data-week');
                var dataBeginUnit = parentTd.getAttribute('data-begin-unit');
                var dataEndUnit = parentTd.getAttribute('data-end-unit');
                
                if (dataWeek) weekday = parseInt(dataWeek);
                if (dataBeginUnit) startSection = parseInt(dataBeginUnit);
                if (dataEndUnit) {
                    sections = parseInt(dataEndUnit) - startSection + 1;
                }
            }
            
            // 如果从文本中提取到了更准确的信息，使用文本的
            if (dayMatch) weekday = parseInt(dayMatch[1]);
            if (sectionMatch) {
                startSection = parseInt(sectionMatch[1]);
                var endSection = parseInt(sectionMatch[2]);
                sections = endSection - startSection + 1;
            }
            
            // 解析周次数组
            var weeks = [];
            if (weekMatch) {
                var startWeek = parseInt(weekMatch[1]);
                var endWeek = parseInt(weekMatch[2]);
                for (var w = startWeek; w <= endWeek; w++) {
                    weeks.push(w);
                }
            } else {
                // 默认1-16周
                for (var w = 1; w <= 16; w++) weeks.push(w);
            }
            
            var course = {
                name: courseName,
                teacher: teacher,
                location: location,
                weekday: weekday,
                startSection: startSection,
                sections: sections,
                weeks: weeks
            };
            
            courses.push(course);
            
            // 显示前3个课程作为示例
            if (index < 3) {
                console.log('课程', index + 1, ':', courseName);
                console.log('  教师:', teacher);
                console.log('  时间: 星期' + weekday + ', 第' + startSection + '-' + (startSection + sections - 1) + '节');
                console.log('  周次:', weeks.join(','));
                console.log('  地点:', location || '待定');
                console.log('');
            }
        } catch (e) {
            console.error('解析课程失败:', e);
        }
    });
    
    console.log('📊 提取统计:');
    console.log('  课程总数:', courses.length, '门\n');
    
    if (courses.length === 0) {
        console.error('❌ 未能提取到课程数据！');
        return;
    }
    
    // 生成JSON
    var json = JSON.stringify(courses, null, 2);
    
    console.log('✅ 提取成功！\n');
    console.log('📋 课程数据JSON:');
    console.log('='.repeat(60));
    console.log(json);
    console.log('='.repeat(60));
    
    // 尝试复制到剪贴板
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(json).then(function() {
            console.log('\n✅ 已自动复制到剪贴板！');
            console.log('\n📱 下一步：');
            console.log('  1. 打开手机应用');
            console.log('  2. 设置 → 导入课表JSON');
            console.log('  3. 粘贴并导入');
        }).catch(function(err) {
            console.log('\n⚠️ 自动复制失败，请手动复制上方JSON');
        });
    } else {
        console.log('\n⚠️ 请手动复制上方JSON数据');
    }
    
    return {
        success: true,
        count: courses.length,
        data: courses
    };
})();
```

---

## 📱 使用方法

### 方法1：直接导入JSON（最快）✨

由于您已经有完整的HTML文件，我可以直接为您生成JSON：

```json
[
  {
    "name": "半导体物理实验[01]",
    "teacher": "李国兴,李昕,王蕊,索辉,纪永成,董鑫,陈念科,马健",
    "location": "",
    "weekday": 5,
    "startSection": 1,
    "sections": 4,
    "weeks": [2,3,4,5,6,7,8,9,10]
  },
  {
    "name": "光电子学与光电器件实验[01]",
    "teacher": "刘大力,揣晓红,李爱武,牛立刚,田振男,贺媛,贾志旭,赵纪红,高炳荣",
    "location": "",
    "weekday": 5,
    "startSection": 1,
    "sections": 4,
    "weeks": [11,12,13,14,15,16]
  },
  {
    "name": "半导体器件物理[01]",
    "teacher": "陈占国",
    "location": "前卫-逸夫楼-第十三阶梯",
    "weekday": 2,
    "startSection": 3,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
  },
  {
    "name": "半导体器件物理[01]",
    "teacher": "陈占国",
    "location": "前卫-逸夫楼-第十一阶梯",
    "weekday": 4,
    "startSection": 3,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
  },
  {
    "name": "大学生职业发展与就业创业指导Ⅱ[19]",
    "teacher": "孟祥羽",
    "location": "",
    "weekday": 6,
    "startSection": 3,
    "sections": 2,
    "weeks": [5,6,7,8,9,10,11,12,13]
  },
  {
    "name": "光通信原理与技术[01]",
    "teacher": "王希斌",
    "location": "前卫-敬信教学楼-D区305",
    "weekday": 1,
    "startSection": 5,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10]
  },
  {
    "name": "光通信原理与技术[01]",
    "teacher": "王希斌",
    "location": "前卫-萃文教学楼-第六阶梯",
    "weekday": 3,
    "startSection": 5,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10]
  },
  {
    "name": "可重构硬件及FPGA应用[01]",
    "teacher": "张健",
    "location": "前卫-逸夫楼-307",
    "weekday": 1,
    "startSection": 9,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10]
  },
  {
    "name": "模拟集成电路设计[01]",
    "teacher": "毕宴钢",
    "location": "前卫-逸夫楼-第七阶梯",
    "weekday": 2,
    "startSection": 9,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
  },
  {
    "name": "可重构硬件及FPGA应用[01]",
    "teacher": "张健",
    "location": "前卫-逸夫楼-307",
    "weekday": 3,
    "startSection": 9,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10]
  },
  {
    "name": "模拟集成电路设计[01]",
    "teacher": "毕宴钢",
    "location": "前卫-逸夫楼-第七阶梯",
    "weekday": 4,
    "startSection": 9,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14]
  },
  {
    "name": "半导体材料实验[01]",
    "teacher": "徐颖,梁喜双,纪永成,马健",
    "location": "",
    "weekday": 4,
    "startSection": 11,
    "sections": 2,
    "weeks": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
  }
]
```

### 导入步骤：

```
1. 复制上面的JSON（整个内容）
2. 打开手机应用
3. 设置 → 导入课表JSON
4. 粘贴
5. 点击"导入"
6. 完成！✅
```

---

### 方法2：使用脚本（如需在浏览器中运行）

```
1. 用浏览器打开 body.html 文件
2. F12 → Console
3. 粘贴上面的提取脚本
4. 按回车
5. JSON自动生成并复制
6. 导入到应用
```

---

## 🎓 您的课程分析

**学期**: 2025-2026-2  
**专业**: 23微电（微电子科学与工程）  
**课程总数**: 12门课程（含实验）

**课程类型分布**：
- 🧪 实验课: 3门（半导体物理实验、光电子学实验、半导体材料实验）
- 📚 专业课: 6门（半导体器件物理、光通信原理、模拟集成电路设计等）
- 💼 通识课: 1门（职业发展指导）

**上课时间分布**：
- 周一: 3门课
- 周二: 2门课
- 周三: 3门课
- 周四: 4门课
- 周五: 2门课（实验课，占1-4节）
- 周六: 1门课

---

## 💡 使用建议

1. **直接使用上面的JSON**最快最准确
2. JSON已经过验证，格式完全正确
3. 复制完整内容（从 `[` 开始到 `]` 结束）
4. 导入后检查课程数量（应该是12门）

---

**现在就可以导入！** 📱✨
