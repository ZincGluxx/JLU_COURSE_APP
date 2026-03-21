# Android虚拟机调试快速启动脚本

Write-Host "🤖 Android虚拟机调试启动脚本" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# 检查Flutter环境
Write-Host "`n📋 检查Flutter环境..." -ForegroundColor Yellow
try {
    flutter --version
    Write-Host "✅ Flutter环境正常" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter未安装或未添加到PATH，请先安装Flutter" -ForegroundColor Red
    Write-Host "下载地址: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# 检查Android环境
Write-Host "`n📱 检查Android环境..." -ForegroundColor Yellow
flutter doctor --android-licenses

# 获取可用设备和模拟器
Write-Host "`n🔍 获取可用设备..." -ForegroundColor Yellow
Write-Host "连接的设备:" -ForegroundColor Cyan
flutter devices

Write-Host "`n🔍 可用的Android模拟器:" -ForegroundColor Yellow
flutter emulators

# 提示用户选择操作
Write-Host "`n🚀 请选择操作:" -ForegroundColor Green
Write-Host "1. 启动Android模拟器然后运行应用" -ForegroundColor White
Write-Host "2. 直接运行到已连接的设备" -ForegroundColor White
Write-Host "3. 运行到所有可用设备" -ForegroundColor White
Write-Host "4. 启动特定模拟器" -ForegroundColor White

$choice = Read-Host "`n请输入选择 (1-4)"

switch ($choice) {
    "1" {
        Write-Host "`n🔄 启动默认Android模拟器..." -ForegroundColor Cyan

        # 获取第一个可用模拟器
        $emulators = flutter emulators | Where-Object { $_ -match "•" }
        if ($emulators) {
            $firstEmulator = ($emulators[0] -split "•")[1].Trim() -replace " .*", ""
            Write-Host "启动模拟器: $firstEmulator" -ForegroundColor Yellow

            # 启动模拟器
            Start-Process -NoNewWindow flutter -ArgumentList "emulators", "--launch", $firstEmulator

            # 等待模拟器启动
            Write-Host "⏳ 等待模拟器启动 (30秒)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30

            # 运行应用
            Write-Host "🚀 运行Flutter应用..." -ForegroundColor Green
            flutter run
        } else {
            Write-Host "❌ 未找到可用的Android模拟器" -ForegroundColor Red
            Write-Host "请在Android Studio中创建AVD" -ForegroundColor Yellow
        }
    }

    "2" {
        Write-Host "`n🚀 运行到已连接设备..." -ForegroundColor Green
        flutter run
    }

    "3" {
        Write-Host "`n🚀 运行到所有设备..." -ForegroundColor Green
        flutter run -d all
    }

    "4" {
        Write-Host "`n📱 可用模拟器列表:" -ForegroundColor Cyan
        flutter emulators
        $emulatorId = Read-Host "`n请输入模拟器ID"

        Write-Host "🔄 启动模拟器: $emulatorId" -ForegroundColor Yellow
        Start-Process -NoNewWindow flutter -ArgumentList "emulators", "--launch", $emulatorId

        Start-Sleep -Seconds 30
        Write-Host "🚀 运行Flutter应用..." -ForegroundColor Green
        flutter run
    }

    default {
        Write-Host "❌ 无效选择，退出脚本" -ForegroundColor Red
    }
}

Write-Host "`n📝 调试提示:" -ForegroundColor Cyan
Write-Host "- 按 'r' 进行热重载" -ForegroundColor White
Write-Host "- 按 'R' 进行热重启" -ForegroundColor White
Write-Host "- 按 'q' 退出调试" -ForegroundColor White
Write-Host "- 使用 'flutter logs' 查看详细日志" -ForegroundColor White