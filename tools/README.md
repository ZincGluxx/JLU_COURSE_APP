# 工具脚本说明

本目录包含用于测试和开发的辅助工具。

## jlu_api_test.py

Python 脚本，用于测试吉林大学金智教务系统的 API 接口。

### 功能

- 模拟登录流程
- 获取课程表数据
- 获取成绩数据
- 保存响应数据到 JSON 文件
- 分析数据结构和字段

### 使用方法

1. 确保已安装 Python 3.7+

2. 安装依赖：
   ```bash
   pip install requests beautifulsoup4
   ```

3. 编辑 `jlu_api_test.py`，修改配置：
   ```python
   USERNAME = '你的学号'
   PASSWORD = '你的密码'
   ```

4. 运行脚本：
   ```bash
   python jlu_api_test.py
   ```

5. 查看输出和生成的 JSON 文件：
   - `course_data.json` - 课程表数据
   - `grade_data.json` - 成绩数据

6. 根据输出的字段名更新 Flutter 代码中的字段映射

### 注意事项

- 请勿将包含真实账号密码的脚本提交到公开仓库
- 建议使用测试账号进行开发
- 遵守学校相关规定，不要频繁请求

### 故障排查

如果脚本运行失败：
1. 检查网络连接
2. 确认账号密码正确
3. 对比浏览器中的实际请求
4. 根据错误信息调整代码

### 后续步骤

测试成功后：
1. 将 Python 脚本获取到的字段名映射到 Flutter 代码
2. 更新 `lib/services/jlu_api_service.dart` 中的字段映射
3. 在 Flutter 应用中测试登录和数据获取
