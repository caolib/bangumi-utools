# 生成发布说明脚本
param(
    [Parameter(Mandatory = $false)]
    [string]$LatestTag,
    
    [Parameter(Mandatory = $false)]
    [string]$PreviousTag
)

$ErrorActionPreference = "Stop"

function Get-CommitsBetweenTags {
    param($LatestTag, $PreviousTag)
    
    try {
        # 检查标签是否存在
        $tagExists = git tag -l $LatestTag 2>$null
        
        if (-not $tagExists) {
            # 如果标签不存在，获取从上一个标签到HEAD的提交
            if ($PreviousTag) {
                $commitRange = "$PreviousTag..HEAD"
                Write-Host "标签 $LatestTag 不存在，获取从 $PreviousTag 到 HEAD 的提交记录" -ForegroundColor Cyan
            }
            else {
                # 如果没有上一个标签，获取所有提交
                $commitRange = "HEAD"
                Write-Host "这是第一个版本，获取所有提交记录" -ForegroundColor Cyan
            }
        }
        else {
            $commitRange = if ($PreviousTag) {
                "$PreviousTag..$LatestTag"
            }
            else {
                $LatestTag
            }
            Write-Host "获取提交记录范围: $commitRange" -ForegroundColor Cyan
        }
        
        $commits = git log $commitRange --pretty=format:"%h|%s" 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "无法获取提交记录"
            return @{ feat = @(); fix = @(); others = @() }
        }
        
        $commitList = @{
            feat   = @()
            fix    = @()
            others = @()
        }
        
        foreach ($commit in $commits) {
            if ([string]::IsNullOrWhiteSpace($commit)) { continue }
            
            $parts = $commit -split '\|', 2
            if ($parts.Count -eq 2) {
                $hash = $parts[0].Trim()
                $message = $parts[1].Trim()
                
                $commitObj = @{
                    ShortHash = $hash
                    Message   = $message
                }
                
                if ($message -match '^✨\s*feat') {
                    $commitList.feat += $commitObj
                }
                elseif ($message -match '^🐛\s*fix') {
                    $commitList.fix += $commitObj
                }
                else {
                    $commitList.others += $commitObj
                }
            }
        }
        
        return $commitList
    }
    catch {
        Write-Error "获取提交记录时出错: $_"
        exit 1
    }
}

function Generate-ReleaseNotes {
    param($LatestTag, $PreviousTag, $Commits)
    
    $output = "## 更新内容`n`n"
    
    # 生成 feat 部分
    if ($Commits.feat.Count -gt 0) {
        $output += "### ✨ 新功能`n"
        foreach ($commit in $Commits.feat) {
            $output += "- [$($commit.ShortHash)] $($commit.Message)`n"
        }
        $output += "`n"
    }
    
    # 生成 fix 部分
    if ($Commits.fix.Count -gt 0) {
        $output += "### 🐛 修复`n"
        foreach ($commit in $Commits.fix) {
            $output += "- [$($commit.ShortHash)] $($commit.Message)`n"
        }
        $output += "`n"
    }
    
    # 生成 others 部分
    if ($Commits.others.Count -gt 0) {
        $output += "### 🔧 其他`n"
        foreach ($commit in $Commits.others) {
            $output += "- [$($commit.ShortHash)] $($commit.Message)`n"
        }
        $output += "`n"
    }
    
    # 如果没有任何提交
    if ($Commits.feat.Count -eq 0 -and $Commits.fix.Count -eq 0 -and $Commits.others.Count -eq 0) {
        $output += "本次发布没有新的提交内容。`n`n"
    }
    
    $output += "---`n"
    if ($PreviousTag) {
        $output += "📋 [查看完整更新日志](https://github.com/caolib/git-commit-helper/compare/$PreviousTag...$LatestTag)`n"
    }
    else {
        $output += "📋 [查看完整更新日志](https://github.com/caolib/git-commit-helper/commits/$LatestTag)`n"
    }
    
    return $output
}

# 主逻辑
Write-Host "开始生成发布说明..." -ForegroundColor Green

# 获取标签信息
$allTags = git tag --sort=-v:refname 2>$null | Where-Object { $_ -match '^\d+\.\d+\.\d+$' }

if (-not $LatestTag) {
    $LatestTag = $allTags | Select-Object -First 1
}

if (-not $PreviousTag -and $allTags.Count -gt 1) {
    $PreviousTag = $allTags | Select-Object -Skip 1 -First 1
}

Write-Host "最新标签: $LatestTag" -ForegroundColor Cyan
if ($PreviousTag) {
    Write-Host "上一个标签: $PreviousTag" -ForegroundColor Cyan
}
else {
    Write-Host "这是第一个版本" -ForegroundColor Cyan
}

# 获取提交记录
$commits = Get-CommitsBetweenTags -LatestTag $LatestTag -PreviousTag $PreviousTag

# 生成发布说明
$releaseNotes = Generate-ReleaseNotes -LatestTag $LatestTag -PreviousTag $PreviousTag -Commits $commits

# 保存到文件
$outputPath = Join-Path $PSScriptRoot ".." "docs" "RELEASE.md"
$releaseNotes | Out-File -FilePath $outputPath -Encoding UTF8 -NoNewline

Write-Host "✅ 发布说明已保存到: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "发布说明内容:" -ForegroundColor Yellow
Write-Host $releaseNotes
