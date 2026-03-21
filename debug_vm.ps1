# 虚拟机调试快速启动脚本

## 检查Flutter环境
Write-Host "检查Flutter环境..." -ForegroundColor Cyan
flutter --version

## 获取可用设备
Write-Host "获取可用设备..." -ForegroundColor Cyan
flutter devices

## 启动Web调试（推荐）
Write-Host "启动Web调试..." -ForegroundColor Green
flutter run -d chrome --web-port 7357

## 备选：启动Edge调试
# flutter run -d edge --web-port 7357

## 如果遇到问题，尝试清理和重新获取依赖
# Write-Host "清理项目..." -ForegroundColor Yellow
# flutter clean
# flutter pub get
# flutter run -d chrome --web-port 7357