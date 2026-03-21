@echo off
chcp 65001 >nul
title JLU课程表 - Android Studio AVD调试

echo.
echo 🤖 吉林大学课程表 - Android Studio AVD 调试
echo ==============================================
echo.

REM 设置本地Flutter路径
set "FLUTTER_PATH=%~dp0flutter\bin"
set "PATH=%FLUTTER_PATH%;%PATH%"

echo 📋 使用本地Flutter工具链...
echo Flutter路径: %FLUTTER_PATH%
echo.

REM 检查Flutter版本
echo 🔧 检查Flutter版本:
"%FLUTTER_PATH%\flutter.bat" --version
if %errorlevel% neq 0 (
    echo ❌ 本地Flutter工具链异常
    pause
    exit /b 1
)
echo.

echo 📱 检查Android Studio AVD状态...
"%FLUTTER_PATH%\flutter.bat" devices
echo.

echo 🚀 可用的Android模拟器:
"%FLUTTER_PATH%\flutter.bat" emulators
echo.

echo 💡 提示: 如果没有看到模拟器，请先在Android Studio中启动AVD
echo.

REM 询问用户是否需要启动模拟器
set /p "start_emulator=是否需要启动模拟器？(y/N): "
if /I "%start_emulator%"=="y" (
    echo 📱 请选择要启动的模拟器ID:
    "%FLUTTER_PATH%\flutter.bat" emulators
    set /p "emulator_id=请输入模拟器ID: "
    echo 🔄 启动模拟器: !emulator_id!
    start "" "%FLUTTER_PATH%\flutter.bat" emulators --launch !emulator_id!
    echo ⏳ 等待模拟器启动 (30秒)...
    timeout /t 30 /nobreak >nul
)

echo.
echo 🚀 启动Android调试...
echo 📝 调试快捷键:
echo   - 按 'r' 进行热重载
echo   - 按 'R' 进行热重启
echo   - 按 'q' 退出调试
echo   - 按 'h' 查看帮助
echo.

REM 运行应用
"%FLUTTER_PATH%\flutter.bat" run --verbose

echo.
echo 📊 调试结束
pause