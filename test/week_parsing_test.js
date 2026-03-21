/**
 * 间周上课解析逻辑测试
 * 此文件用于测试在simple_webview_login.dart中实现的JavaScript周次解析逻辑
 */

// 模拟解析函数（更新版本，支持多段周次）
function parseWeeks(roomText) {
  var weeks = [];

  // 先处理多段周次格式，如"1-4周,6-13周"
  var weekText = roomText;
  // 提取所有周次信息（可能有多段）
  var weekSegments = [];

  // 查找所有可能的周次段
  var allWeekMatches = weekText.match(/([\\d,\\-]+周(?:[\\s]*[（(]([单双])[周]?[）)])?)/g);
  if (allWeekMatches && allWeekMatches.length > 0) {
    // 处理每个匹配到的周次段
    allWeekMatches.forEach(function(segment) {
      // 分割逗号分隔的多段周次
      var parts = segment.split(/,(?=\\d+)/); // 按数字前的逗号分割
      parts.forEach(function(part) {
        if (part.trim()) {
          weekSegments.push(part.trim());
        }
      });
    });
  }

  // 如果没有匹配到标准格式，尝试直接分割逗号
  if (weekSegments.length === 0) {
    // 备用方案：查找类似 "1-4周,6-13周" 的格式
    var multiRangeMatch = weekText.match(/((?:\\d+\\-\\d+周(?:\\s*[,，]\\s*)?)+)/);
    if (multiRangeMatch) {
      var rangeText = multiRangeMatch[1];
      weekSegments = rangeText.split(/[,，]/).map(function(s) { return s.trim(); }).filter(function(s) { return s; });
    }
  }

  console.log('分解的周次段:', weekSegments);

  // 处理每个周次段
  weekSegments.forEach(function(segment) {
    // 检查是否是间周上课格式
    var intervalMatch = segment.match(/(\\d+)-(\\d+)周[\\s]*[（(]([单双])[周]?[）)]/);
    if (intervalMatch) {
      // 间周上课：如"1-15周(单周)" 或 "2-16周(双周)"
      var start = parseInt(intervalMatch[1]);
      var end = parseInt(intervalMatch[2]);
      var type = intervalMatch[3]; // "单" 或 "双"

      console.log('检测到间周上课:', start, '-', end, '周(', type, ')');

      if (type === '单') {
        // 单周：奇数周
        for (var w = start; w <= end; w++) {
          if (w % 2 === 1 && weeks.indexOf(w) === -1) {
            weeks.push(w);
          }
        }
      } else if (type === '双') {
        // 双周：偶数周
        for (var w = start; w <= end; w++) {
          if (w % 2 === 0 && weeks.indexOf(w) === -1) {
            weeks.push(w);
          }
        }
      }
    } else {
      // 普通连续周次格式
      var weekMatch = segment.match(/(\\d+)-(\\d+)周/);
      if (weekMatch) {
        // 连续周次："2-10周" -> [2,3,4,5,6,7,8,9,10]
        var start = parseInt(weekMatch[1]);
        var end = parseInt(weekMatch[2]);
        console.log('连续周次:', start, '-', end, '周');
        for (var w = start; w <= end; w++) {
          if (weeks.indexOf(w) === -1) {
            weeks.push(w);
          }
        }
      } else {
        // 单周格式："5周" -> [5]
        var singleMatch = segment.match(/(\\d+)周/);
        if (singleMatch) {
          var w = parseInt(singleMatch[1]);
          console.log('单周:', w, '周');
          if (weeks.indexOf(w) === -1) {
            weeks.push(w);
          }
        }
      }
    }
  });

  // 如果还是没有解析到周次，尝试最基础的解析
  if (weeks.length === 0) {
    // 先检查是否是间周上课格式
    var intervalMatch = roomText.match(/(\\d+)-(\\d+)周[\\s]*[（(]([单双])[周]?[）)]/);
    if (intervalMatch) {
      var start = parseInt(intervalMatch[1]);
      var end = parseInt(intervalMatch[2]);
      var type = intervalMatch[3];

      if (type === '单') {
        for (var w = start; w <= end; w++) {
          if (w % 2 === 1) {
            weeks.push(w);
          }
        }
      } else if (type === '双') {
        for (var w = start; w <= end; w++) {
          if (w % 2 === 0) {
            weeks.push(w);
          }
        }
      }
    } else {
      // 普通连续周次格式
      var weekMatch = roomText.match(/(\\d+)-(\\d+)周/);
      if (weekMatch) {
        var start = parseInt(weekMatch[1]);
        var end = parseInt(weekMatch[2]);
        for (var w = start; w <= end; w++) {
          weeks.push(w);
        }
      } else {
        // 单周格式
        var singleMatch = roomText.match(/(\\d+)周/);
        if (singleMatch) {
          weeks.push(parseInt(singleMatch[1]));
        }
      }
    }
  }

  // 排序周次数组
  weeks.sort(function(a, b) { return a - b; });
  return weeks;
}

// 测试用例
const testCases = [
  // 连续周次测试
  {
    input: "2-10周,星期5,第1节-第4节",
    expected: [2, 3, 4, 5, 6, 7, 8, 9, 10],
    description: "连续周次：2-10周"
  },
  {
    input: "1-16周,星期2,第3节-第4节",
    expected: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    description: "连续周次：1-16周"
  },

  // 单周测试
  {
    input: "5周,星期3,第7节-第8节",
    expected: [5],
    description: "单周：5周"
  },

  // 间周上课测试 - 单周
  {
    input: "1-15周(单周),星期1,第5节-第6节",
    expected: [1, 3, 5, 7, 9, 11, 13, 15],
    description: "间周上课：1-15周(单周)"
  },
  {
    input: "3-13周(单),星期4,第9节-第10节",
    expected: [3, 5, 7, 9, 11, 13],
    description: "间周上课：3-13周(单)"
  },
  {
    input: "1-15周（单周）,星期2,第1节-第2节",
    expected: [1, 3, 5, 7, 9, 11, 13, 15],
    description: "间周上课：1-15周（单周）中文括号"
  },

  // 间周上课测试 - 双周
  {
    input: "2-16周(双周),星期5,第3节-第4节",
    expected: [2, 4, 6, 8, 10, 12, 14, 16],
    description: "间周上课：2-16周(双周)"
  },
  {
    input: "4-14周(双),星期6,第11节-第12节",
    expected: [4, 6, 8, 10, 12, 14],
    description: "间周上课：4-14周(双)"
  },
  {
    input: "2-14周（双周）,星期3,第7节-第8节",
    expected: [2, 4, 6, 8, 10, 12, 14],
    description: "间周上课：2-14周（双周）中文括号"
  },

  // 多段周次测试
  {
    input: "1-4周,6-13周,星期5,第5节-第6节",
    expected: [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13],
    description: "多段周次：1-4周,6-13周（跳过第5周）"
  },
  {
    input: "2-5周,8-12周,星期1,第1节-第2节",
    expected: [2, 3, 4, 5, 8, 9, 10, 11, 12],
    description: "多段周次：2-5周,8-12周（跳过第6-7周）"
  },
  {
    input: "1-3周,7-9周,15-16周,星期4,第9节-第10节",
    expected: [1, 2, 3, 7, 8, 9, 15, 16],
    description: "三段周次：1-3周,7-9周,15-16周"
  },
  {
    input: "5周,8-10周,星期3,第5节-第6节",
    expected: [5, 8, 9, 10],
    description: "混合格式：单周+连续周次"
  },
];

// 运行测试
console.log("开始运行间周解析测试...\n");
let passCount = 0;
let failCount = 0;

testCases.forEach((testCase, index) => {
  const result = parseWeeks(testCase.input);
  const passed = JSON.stringify(result) === JSON.stringify(testCase.expected);

  if (passed) {
    console.log(`✅ 测试 ${index + 1} 通过: ${testCase.description}`);
    console.log(`   输入: "${testCase.input}"`);
    console.log(`   结果: [${result.join(', ')}]\n`);
    passCount++;
  } else {
    console.log(`❌ 测试 ${index + 1} 失败: ${testCase.description}`);
    console.log(`   输入: "${testCase.input}"`);
    console.log(`   期望: [${testCase.expected.join(', ')}]`);
    console.log(`   实际: [${result.join(', ')}]\n`);
    failCount++;
  }
});

console.log(`测试总结:`);
console.log(`✅ 通过: ${passCount} 个`);
console.log(`❌ 失败: ${failCount} 个`);
console.log(`📊 总计: ${testCases.length} 个测试用例`);

if (failCount === 0) {
  console.log("\n🎉 所有测试都通过了！间周解析逻辑工作正常。");
} else {
  console.log("\n⚠️ 有测试失败，请检查间周解析逻辑。");
}