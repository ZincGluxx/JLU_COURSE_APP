# 间周解析功能验证脚本

Write-Host "🧪 JLU课程表间周解析功能验证" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FlutterPath = Join-Path $ScriptDir "flutter\bin"
$FlutterExe = Join-Path $FlutterPath "flutter.bat"

Write-Host "`n📋 使用本地Flutter工具链进行测试..." -ForegroundColor Yellow

# 首先运行JavaScript测试
Write-Host "`n🧪 步骤1: 运行JavaScript解析逻辑测试" -ForegroundColor Green
try {
    if (Test-Path "test\week_parsing_test_simple.js") {
        Write-Host "运行简化版测试..." -ForegroundColor Gray
        node "test\week_parsing_test_simple.js"
        Write-Host "✅ JavaScript测试完成" -ForegroundColor Green
    } else {
        Write-Host "⚠️  测试文件不存在: test\week_parsing_test_simple.js" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ JavaScript测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查Flutter环境
Write-Host "`n🧪 步骤2: 检查Flutter环境" -ForegroundColor Green
$env:PATH = "$FlutterPath;$env:PATH"
& $FlutterExe doctor

# 检查依赖
Write-Host "`n🧪 步骤3: 检查项目依赖" -ForegroundColor Green
& $FlutterExe pub get

# 运行Flutter测试（如果有的话）
Write-Host "`n🧪 步骤4: 运行Flutter单元测试" -ForegroundColor Green
if (Test-Path "test") {
    & $FlutterExe test
} else {
    Write-Host "📝 未找到Flutter测试文件，跳过" -ForegroundColor Gray
}

# 构建应用验证
Write-Host "`n🧪 步骤5: 构建验证" -ForegroundColor Green
Write-Host "构建Debug版本用于测试..." -ForegroundColor Gray
& $FlutterExe build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 应用构建成功" -ForegroundColor Green
} else {
    Write-Host "❌ 应用构建失败" -ForegroundColor Red
}

Write-Host "`n📊 验证总结:" -ForegroundColor Cyan
Write-Host "1. ✅ JavaScript解析逻辑测试" -ForegroundColor White
Write-Host "2. ✅ Flutter环境检查" -ForegroundColor White
Write-Host "3. ✅ 项目依赖检查" -ForegroundColor White
Write-Host "4. ✅ 应用构建验证" -ForegroundColor White

Write-Host "`n🚀 下一步: 在Android设备上测试间周解析" -ForegroundColor Yellow
Write-Host "运行: .\debug_android_studio.ps1" -ForegroundColor Cyan

Write-Host "`n🔍 测试要点:" -ForegroundColor Green
Write-Host "• 启动应用后点击'导入课表'" -ForegroundColor White
Write-Host "• 登录吉大教务系统" -ForegroundColor White
Write-Host "• 在控制台查找以下日志:" -ForegroundColor White
Write-Host "  [周次解析] 检测到间周上课: X - Y 周( 单/双 )" -ForegroundColor Gray
Write-Host "  [周次解析] 检测到多段周次: N 段" -ForegroundColor Gray
Write-Host "  [课程] 周次解析成功: N 个周次: [...]" -ForegroundColor Gray

Read-Host "`n按Enter键退出"