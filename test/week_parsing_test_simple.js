/**
 * 简化版间周上课解析逻辑测试
 */

// 简化的解析函数（修正版本）
function parseWeeksSimple(roomText) {
  var weeks = [];

  console.log('输入:', roomText);

  // 1. 先尝试匹配间周上课（优先级最高）
  var intervalMatch = roomText.match(/(\d+)-(\d+)周\s*[（(]([单双])[）)周]?/);
  if (intervalMatch) {
    var start = parseInt(intervalMatch[1]);
    var end = parseInt(intervalMatch[2]);
    var type = intervalMatch[3];

    console.log('检测到间周上课:', start, '-', end, '周(', type, ')');

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
  }
  // 2. 尝试匹配多段周次，如 "1-4周,6-13周"
  else {
    var multiRangeMatch = roomText.match(/(\d+-\d+周(?:\s*,\s*\d+-\d+周)*)/);
    if (multiRangeMatch) {
      var ranges = multiRangeMatch[1].split(',');
      console.log('检测到多段周次:', ranges);

      ranges.forEach(function(range) {
        var rangeMatch = range.trim().match(/(\d+)-(\d+)周/);
        if (rangeMatch) {
          var start = parseInt(rangeMatch[1]);
          var end = parseInt(rangeMatch[2]);
          console.log('  处理范围:', start, '-', end);
          for (var w = start; w <= end; w++) {
            if (weeks.indexOf(w) === -1) {
              weeks.push(w);
            }
          }
        }
      });
    }
    // 3. 普通连续周次
    else {
      var weekMatch = roomText.match(/(\d+)-(\d+)周/);
      if (weekMatch) {
        var start = parseInt(weekMatch[1]);
        var end = parseInt(weekMatch[2]);
        console.log('检测到连续周次:', start, '-', end);
        for (var w = start; w <= end; w++) {
          weeks.push(w);
        }
      }
      // 4. 单周
      else {
        var singleMatch = roomText.match(/(\d+)周/);
        if (singleMatch) {
          var w = parseInt(singleMatch[1]);
          console.log('检测到单周:', w);
          weeks.push(w);
        }
      }
    }
  }

  weeks.sort(function(a, b) { return a - b; });
  return weeks;
}

// 测试用例
const testCases = [
  {
    input: "2-10周,星期5,第1节-第4节",
    expected: [2, 3, 4, 5, 6, 7, 8, 9, 10],
    description: "连续周次：2-10周"
  },
  {
    input: "1-15周(单周),星期1,第5节-第6节",
    expected: [1, 3, 5, 7, 9, 11, 13, 15],
    description: "间周上课：1-15周(单周)"
  },
  {
    input: "2-16周(双周),星期5,第3节-第4节",
    expected: [2, 4, 6, 8, 10, 12, 14, 16],
    description: "间周上课：2-16周(双周)"
  },
  {
    input: "1-4周,6-13周,星期5,第5节-第6节",
    expected: [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13],
    description: "多段周次：1-4周,6-13周"
  },
  {
    input: "5周,星期3,第7节-第8节",
    expected: [5],
    description: "单周：5周"
  },
];

// 运行测试
console.log("开始运行简化版解析测试...\n");

testCases.forEach((testCase, index) => {
  console.log(`=== 测试 ${index + 1}: ${testCase.description} ===`);
  const result = parseWeeksSimple(testCase.input);
  const passed = JSON.stringify(result) === JSON.stringify(testCase.expected);

  if (passed) {
    console.log(`✅ 通过 - 结果: [${result.join(', ')}]\n`);
  } else {
    console.log(`❌ 失败`);
    console.log(`   期望: [${testCase.expected.join(', ')}]`);
    console.log(`   实际: [${result.join(', ')}]\n`);
  }
});