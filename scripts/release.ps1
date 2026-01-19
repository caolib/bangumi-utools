# uTools插件发布脚本
# 用于发布 git-commit-helper 插件
param(
    [Parameter()]
    [string]$Version
)

$ErrorActionPreference = "Stop"

# 交互式菜单选择函数
function Show-InteractiveMenu {
    param(
        [string[]]$Options,
        [string]$Title = "请选择选项"
    )
    
    $selectedIndex = 0
    
    Clear-Host
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ""
    
    $menuStartRow = [Console]::CursorTop
    
    for ($i = 0; $i -lt $Options.Length; $i++) {
        if ($i -eq $selectedIndex) {
            Write-Host "→ $($Options[$i])" -ForegroundColor Green
        }
        else {
            Write-Host "  $($Options[$i])" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "使用 ↑↓ 选择，回车确认，ESC 退出" -ForegroundColor Yellow
    
    $lastSelectedIndex = -1
    
    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 {
                # 上箭头
                $selectedIndex = if ($selectedIndex -eq 0) { $Options.Length - 1 } else { $selectedIndex - 1 }
            }
            40 {
                # 下箭头
                $selectedIndex = if ($selectedIndex -eq $Options.Length - 1) { 0 } else { $selectedIndex + 1 }
            }
            13 {
                # 回车
                return $selectedIndex
            }
            27 {
                # ESC
                return -1
            }
            default {
                continue
            }
        }
        
        if ($selectedIndex -ne $lastSelectedIndex) {
            [Console]::SetCursorPosition(0, $menuStartRow)
            
            for ($i = 0; $i -lt $Options.Length; $i++) {
                if ($i -eq $selectedIndex) {
                    Write-Host "→ $($Options[$i])" -ForegroundColor Green
                }
                else {
                    Write-Host "  $($Options[$i])" -ForegroundColor White
                }
            }
            
            $lastSelectedIndex = $selectedIndex
        }
    }
}

# 获取版本号
try {
    $latestTag = git describe --tags --abbrev=0 2>$null
    if ($LASTEXITCODE -eq 0 -and $latestTag) {
        Write-Host "当前最新的标签: $latestTag" -ForegroundColor Green
        
        # 解析版本号 (支持 0.2.0 格式)
        if ($latestTag -match '^v?(\d+)\.(\d+)\.(\d+)') {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            $patch = [int]$matches[3]
            
            # 生成预设版本选项
            $patchVersion = "$major.$minor.$($patch + 1)"
            $minorVersion = "$major.$($minor + 1).0"
            $majorVersion = "$($major + 1).0.0"
            
            $options = @(
                "$patchVersion (补丁版本 - bug修复)",
                "$minorVersion (次要版本 - 新功能)",
                "$majorVersion (主要版本 - 重大更新)",
                "手动输入版本号"
            )
            
            $choice = Show-InteractiveMenu -Options $options -Title "选择版本类型 (当前: $latestTag)"
            
            if ($choice -eq -1) {
                Write-Host "已取消操作" -ForegroundColor Yellow
                exit 0
            }
            
            switch ($choice) {
                0 { $Version = $patchVersion }
                1 { $Version = $minorVersion }
                2 { $Version = $majorVersion }
                3 { 
                    Clear-Host
                    $Version = Read-Host "请手动输入版本号 (例如: 0.3.0)"
                }
            }
        }
        else {
            Write-Host "无法解析当前标签格式，请手动输入版本号" -ForegroundColor Yellow
            $Version = Read-Host "请输入版本号 (例如: 0.2.0)"
        }
    }
    else {
        Write-Host "未找到任何标签，这可能是第一个版本" -ForegroundColor Yellow
        Write-Host "建议使用 0.1.0 作为第一个版本" -ForegroundColor Cyan
        $Version = Read-Host "请输入版本号 (建议: 0.1.0)"
    }
}
catch {
    Write-Host "获取标签信息失败，请手动输入版本号" -ForegroundColor Yellow
    $Version = Read-Host "请输入版本号"
}

# 验证版本号
if (-not $Version) {
    Write-Host "错误: 版本号不能为空" -ForegroundColor Red
    exit 1
}

# 去掉版本号前缀 v（如果有的话）
$VersionNumber = $Version -replace '^v', ''

# 验证版本号格式
if ($VersionNumber -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "错误: 版本号格式不正确，应该是 x.y.z 格式" -ForegroundColor Red
    exit 1
}

# 标签使用 v 前缀
$TagVersion = "v$VersionNumber"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "准备发布 Git Commit Helper v$VersionNumber" -ForegroundColor Green
Write-Host "标签: $TagVersion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤 1: 创建临时标签并生成发布说明
Write-Host "[1/5] 创建临时标签并生成发布说明..." -ForegroundColor Yellow

# 创建临时标签用于生成发布说明
Write-Host "创建临时标签 $TagVersion..." -ForegroundColor Cyan
git tag $TagVersion 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "警告: 标签 $TagVersion 可能已存在，将使用现有标签" -ForegroundColor Yellow
}

# 获取上一个标签
$previousTag = git tag --sort=-v:refname | Where-Object { 
    ($_ -match '^\d+\.\d+\.\d+$' -or $_ -match '^v\d+\.\d+\.\d+$') -and $_ -ne $TagVersion 
} | Select-Object -First 1

Write-Host "当前版本: $TagVersion" -ForegroundColor Cyan
if ($previousTag) {
    Write-Host "上一个版本: $previousTag" -ForegroundColor Cyan
    & "$PSScriptRoot\generate-release-notes.ps1" -LatestTag $TagVersion -PreviousTag $previousTag
}
else {
    Write-Host "这是第一个版本" -ForegroundColor Cyan
    & "$PSScriptRoot\generate-release-notes.ps1" -LatestTag $TagVersion
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 生成发布说明失败" -ForegroundColor Red
    # 清理临时标签
    git tag -d $TagVersion 2>$null
    exit 1
}

# 删除临时标签
Write-Host "删除临时标签..." -ForegroundColor Cyan
git tag -d $TagVersion 2>$null

# 提示用户审查发布说明
Write-Host ""
Write-Host "请审查 docs/RELEASE.md 文件，确认发布说明无误" -ForegroundColor Cyan
Write-Host "按回车键继续..." -ForegroundColor Yellow
Read-Host | Out-Null

# 步骤 2: 提交更改
Write-Host ""
Write-Host "[2/5] 提交更改..." -ForegroundColor Yellow
git add .

$gitStatus = git status --porcelain
if (-not [string]::IsNullOrWhiteSpace($gitStatus)) {
    git commit -m "🐳 chore: 发布 $TagVersion"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 提交更改失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ 更改已提交" -ForegroundColor Green
}
else {
    Write-Host "没有需要提交的更改" -ForegroundColor Yellow
}

# 步骤 3: 推送代码
Write-Host ""
Write-Host "[3/5] 推送代码到远程仓库..." -ForegroundColor Yellow
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 推送代码失败" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 代码已推送" -ForegroundColor Green

# 步骤 4: 创建并推送标签
Write-Host ""
Write-Host "[4/5] 创建并推送标签 $TagVersion..." -ForegroundColor Yellow

# 清理可能存在的旧标签
git tag -d $TagVersion 2>$null

# 创建新标签
git tag $TagVersion
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 创建标签失败" -ForegroundColor Red
    exit 1
}

# 推送标签
git push origin $TagVersion
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 推送标签失败" -ForegroundColor Red
    git tag -d $TagVersion
    exit 1
}

Write-Host "✅ 标签已推送" -ForegroundColor Green

# 步骤 5: 完成
Write-Host ""
Write-Host "[5/5] 发布流程完成！" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 发布流程已完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作:" -ForegroundColor Yellow
Write-Host "1. GitHub Actions 会自动构建并创建 Release" -ForegroundColor White
Write-Host "2. 访问 https://github.com/caolib/git-commit-helper/actions 查看构建进度" -ForegroundColor White
Write-Host "3. 构建完成后，在 https://github.com/caolib/git-commit-helper/releases 查看发布" -ForegroundColor White
Write-Host ""
Write-Host "注意事项:" -ForegroundColor Yellow
Write-Host "- 安装文件路径格式: build/git commit helper-$VersionNumber.upxs" -ForegroundColor White
Write-Host "- 请确保该文件存在后再运行 GitHub Actions" -ForegroundColor White
