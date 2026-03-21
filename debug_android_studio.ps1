# JLU课程表 - Android Studio AVD 调试脚本 (本地Flutter)

Write-Host "🤖 吉林大学课程表 - Android Studio AVD 调试" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 获取本地Flutter路径
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FlutterPath = Join-Path $ScriptDir "flutter\bin"
$FlutterExe = Join-Path $FlutterPath "flutter.bat"

Write-Host "`n📋 使用本地Flutter工具链..." -ForegroundColor Yellow
Write-Host "Flutter路径: $FlutterPath" -ForegroundColor Gray

# 设置环境变量
$env:PATH = "$FlutterPath;$env:PATH"

# 检查Flutter版本
Write-Host "`n🔧 检查Flutter版本:" -ForegroundColor Yellow
try {
    & $FlutterExe --version
    Write-Host "✅ 本地Flutter工具链正常" -ForegroundColor Green
} catch {
    Write-Host "❌ 本地Flutter工具链异常: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "按Enter键退出"
    exit 1
}

# 检查Android环境
Write-Host "`n📱 检查Android环境:" -ForegroundColor Yellow
& $FlutterExe doctor --android-licenses

# 获取设备列表
Write-Host "`n📱 当前连接的设备:" -ForegroundColor Yellow
$devices = & $FlutterExe devices
Write-Host $devices -ForegroundColor White

Write-Host "`n🚀 可用的Android Studio模拟器:" -ForegroundColor Yellow
$emulators = & $FlutterExe emulators
Write-Host $emulators -ForegroundColor White

# 检查是否有设备连接
$hasDevices = $devices | Select-String "android|emulator" -Quiet

if (-not $hasDevices) {
    Write-Host "`n⚠️  未检测到Android设备或模拟器" -ForegroundColor Yellow
    Write-Host "📱 请在Android Studio中启动AVD，或者使用以下选项:" -ForegroundColor Cyan

    $choice = Read-Host "`n请选择操作:`n1. 启动Android Studio模拟器`n2. 等待手动启动设备后继续`n3. 退出`n请输入选择 (1-3)"

    switch ($choice) {
        "1" {
            if ($emulators -match "•") {
                Write-Host "`n📱 可用模拟器列表:" -ForegroundColor Cyan
                $emulatorLines = $emulators -split "`n" | Where-Object { $_ -match "•" }
                for ($i = 0; $i -lt $emulatorLines.Count; $i++) {
                    Write-Host "$($i+1). $($emulatorLines[$i])" -ForegroundColor White
                }

                $emulatorChoice = Read-Host "`n请选择模拟器编号"
                $selectedEmulator = $emulatorLines[$emulatorChoice - 1]

                if ($selectedEmulator -match "• (.+?)(?:\s|$)") {
                    $emulatorId = $matches[1]
                    Write-Host "`n🔄 启动模拟器: $emulatorId" -ForegroundColor Yellow

                    Start-Process -NoNewWindow -FilePath $FlutterExe -ArgumentList "emulators", "--launch", $emulatorId

                    Write-Host "⏳ 等待模拟器启动 (40秒)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 40
                } else {
                    Write-Host "❌ 无法解析模拟器ID" -ForegroundColor Red
                    exit 1
                }
            } else {
                Write-Host "❌ 未找到可用模拟器，请在Android Studio中创建AVD" -ForegroundColor Red
                exit 1
            }
        }
        "2" {
            Write-Host "⏳ 等待设备连接..." -ForegroundColor Yellow
            do {
                Start-Sleep -Seconds 3
                $devices = & $FlutterExe devices
                $hasDevices = $devices | Select-String "android|emulator" -Quiet
                Write-Host "." -NoNewline -ForegroundColor Gray
            } while (-not $hasDevices)
            Write-Host "`n✅ 检测到设备连接" -ForegroundColor Green
        }
        "3" { exit 0 }
        default {
            Write-Host "❌ 无效选择，退出" -ForegroundColor Red
            exit 1
        }
    }
}

# 最终设备检查
Write-Host "`n📱 最终设备状态:" -ForegroundColor Yellow
& $FlutterExe devices

Write-Host "`n🚀 启动Flutter应用调试..." -ForegroundColor Green
Write-Host "📝 调试快捷键提示:" -ForegroundColor Cyan
Write-Host "  - 按 'r' 进行热重载" -ForegroundColor White
Write-Host "  - 按 'R' 进行热重启" -ForegroundColor White
Write-Host "  - 按 'q' 退出调试" -ForegroundColor White
Write-Host "  - 按 'h' 查看更多帮助" -ForegroundColor White
Write-Host "`n🔍 间周解析功能验证:" -ForegroundColor Cyan
Write-Host "  - 在应用中点击'导入课表'" -ForegroundColor White
Write-Host "  - 登录吉大教务系统" -ForegroundColor White
Write-Host "  - 观察控制台输出，查找'[周次解析]'日志" -ForegroundColor White

Write-Host "`n" -ForegroundColor White

# 运行Flutter应用
try {
    & $FlutterExe run --verbose
} catch {
    Write-Host "`n❌ 运行失败: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host "`n📊 调试会话结束" -ForegroundColor Yellow
    Read-Host "按Enter键退出"
}