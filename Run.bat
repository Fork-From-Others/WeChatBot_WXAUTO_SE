@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ---------------------------
:: 检查微信版本
:: ---------------------------
:: 依次检测 Weixin 和 WeChat 注册表路径，优先 Weixin
:: ---------------------------
set "wxversion="
rem 优先依次检测 Weixin 和 WeChat 的 DisplayVersion
for %%K in (
    "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Weixin"
    "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\WeChat"
) do (
    for /f "tokens=2,*" %%i in ('reg query %%K /v DisplayVersion 2^>nul ^| find "DisplayVersion"') do (
        set "wxversion=%%j"
        set "RegPath=%%K"
        goto :found_wxversion
    )
)
if not defined wxversion (
    echo ❌ 未检测到微信安装，或无法读取注册表，请确认微信已正确安装。
    pause
    exit /b 1
)
:found_wxversion

if not defined wxversion (
    echo ❌ 未能正确获取微信版本号，请确认微信已安装并重试。
    pause
    exit /b 1
)

:: 解析主版本号
for /f "tokens=1 delims=." %%a in ("!wxversion!") do (
    set "major=%%a"
)

:: 只判断主版本
if !major! lss 3 (
    echo ❌ 当前微信版本 !wxversion!，请前往[https://dldir1v6.qq.com/weixin/Windows/WeChatSetup.exe/]升级到3.9及以上版本。
    pause
    exit /b 1
)
if !major! geq 4 (
    echo ❌ 当前微信版本 !wxversion!，暂不支持4及以上版本，前往下载合适版本的[https://dldir1v6.qq.com/weixin/Windows/WeChatSetup.exe]。
    pause
    exit /b 1
)

echo ✅ 微信版本检查通过：!wxversion!

:: ---------------------------
:: 检查 Python 是否安装
:: ---------------------------
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python 未安装，请先安装 Python 3.8 - 3.11 版本。
    pause
    exit /b 1
)

:: 获取 Python 版本
for /f "tokens=2,*" %%i in ('python --version 2^>^&1') do set "pyversion=%%i"
for /f "tokens=1,2 delims=." %%a in ("%pyversion%") do (
    set major=%%a
    set minor=%%b
)

:: 检查版本范围
if %major% lss 3 (
    echo ❌ 当前 Python 版本 %pyversion%，请使用 Python 3.8+
    pause
    exit /b 1
)
if %major% gtr 3 (
    echo ❌ 当前 Python 版本 %pyversion%，请使用 Python 3.8-3.11 之间版本
    pause
    exit /b 1
)
if %minor% lss 8 (
    echo ❌ Python 版本太旧，最低要求为 Python 3.8
    pause
    exit /b 1
)
if %minor% geq 12 (
    echo ❌ 暂不支持 Python 3.12 及以上版本
    pause
    exit /b 1
)

echo ✅ Python 版本检查通过：%pyversion%

:: ---------------------------
:: 检查 pip 是否存在
:: ---------------------------
python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ pip 未安装，请先安装 pip。
    pause
    exit /b 1
)

:: ---------------------------
:: 选择最快的 pip 源
:: ---------------------------
echo 🚀 正在检测可用镜像源...

:: 阿里源
python -m pip install --upgrade pip --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if !errorlevel! equ 0 (
    set "SOURCE_URL=https://mirrors.aliyun.com/pypi/simple/"
    set "TRUSTED_HOST=mirrors.aliyun.com"
    echo ✅ 使用阿里源
    goto :INSTALL
)

:: 清华源
python -m pip install --upgrade pip --index-url https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn
if !errorlevel! equ 0 (
    set "SOURCE_URL=https://pypi.tuna.tsinghua.edu.cn/simple"
    set "TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn"
    echo ✅ 使用清华源
    goto :INSTALL
)

:: 官方源
python -m pip install --upgrade pip --index-url https://pypi.org/simple
if !errorlevel! equ 0 (
    set "SOURCE_URL=https://pypi.org/simple"
    set "TRUSTED_HOST="
    echo ✅ 使用官方源
    goto :INSTALL
)

echo ❌ 无可用镜像源，请检查网络
pause
exit /b 1

:INSTALL
echo 🔄 正在安装依赖...

if "!TRUSTED_HOST!"=="" (
    python -m pip install -r requirements.txt -f ./libs --index-url !SOURCE_URL!
) else (
    python -m pip install -r requirements.txt -f ./libs --index-url !SOURCE_URL! --trusted-host !TRUSTED_HOST!
)

if !errorlevel! neq 0 (
    echo ❌ 安装依赖失败，请检查网络或 requirements.txt 是否存在
    pause
    exit /b 1
)

echo ✅ 所有依赖安装成功！

:: 清屏
cls

:: ---------------------------
:: 检查程序更新
:: ---------------------------

echo 🟢 检查程序更新...

python updater.py

echo ✅ 程序更新完成！

:: 清屏
cls

:: ---------------------------
:: 启动程序
:: ---------------------------
echo 🟢 启动主程序...
python config_editor.py
