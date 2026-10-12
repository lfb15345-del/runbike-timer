# Android版APKを作って、配布用フォルダとGoogleドライブまで届ける
# 使い方（PowerShell）:  powershell -ExecutionPolicy Bypass -File tool\build_android.ps1
#
# ・日本語を含むパスではAndroidのビルドが失敗するため、英語パスの C:\rb_build で作る
# ・C:\rb_build は毎回 GitHub の最新に揃える（git pull だと自動生成ファイルの差分で失敗するため reset）
# ・できたAPKの中のバージョンを確かめてから配る（中身の古いAPKを配った事故の再発防止）
# ・Googleドライブには「ランバイクタイマー_最新.apk」を上書きする。ファイルの共有リンクが変わらないので、
#   一度共有したリンクをそのまま使い回せる

$ErrorActionPreference = 'Stop'
$buildDir   = 'C:\rb_build'
$distDir    = 'C:\Users\jien0\Documents\ランバイク\配布用'
$driveDir   = 'H:\マイドライブ\ランバイクタイマー配布'
$latestName = 'ランバイクタイマー_最新.apk'

# 1. ビルド用フォルダを最新に揃える
Set-Location $buildDir
git fetch -q origin
git reset -q --hard origin/master
$wanted = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)\+(\d+)').Matches[0]
$versionName = $wanted.Groups[1].Value
$versionCode = $wanted.Groups[2].Value
Write-Output "ビルドするバージョン: $versionName ($versionCode)"

# 2. ビルド
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'APKのビルドに失敗しました' }
$apk = Join-Path $buildDir 'build\app\outputs\flutter-apk\app-release.apk'

# 3. 中身のバージョンと署名を確認
$bt = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Directory | Sort-Object Name -Descending | Select-Object -First 1
$aapt = Get-ChildItem "$($bt.FullName)\aapt*.exe" | Select-Object -First 1
$badging = (& $aapt.FullName dump badging $apk | Select-Object -First 1)
if ($badging -notmatch "versionCode='$versionCode'" -or $badging -notmatch "versionName='$versionName'") {
    throw "APKの中身のバージョンが違います: $badging"
}
$cert = (& "$($bt.FullName)\apksigner.bat" verify --print-certs $apk | Select-String 'SHA-256').ToString()
Write-Output "確認OK: $badging"
Write-Output $cert

# 4. 配布用フォルダへ（古い版は _使わない(中身が古い) に退避）
$versioned = "ランバイクタイマー_v${versionName}_開発署名.apk"
$oldDir = Join-Path $distDir '_使わない(中身が古い)'
New-Item -ItemType Directory -Force $oldDir | Out-Null
Get-ChildItem $distDir -Filter 'ランバイクタイマー_v*_開発署名.apk' |
    Where-Object { $_.Name -ne $versioned -and $_.Name -notmatch '_v1\.0\.[23]_' } |
    Move-Item -Destination $oldDir -Force
Copy-Item $apk (Join-Path $distDir $versioned) -Force

# 5. Googleドライブへ（同じ名前で上書き＝共有リンクはそのまま）
New-Item -ItemType Directory -Force $driveDir | Out-Null
Copy-Item $apk (Join-Path $driveDir $latestName) -Force
Get-ChildItem $driveDir -Filter 'ランバイクタイマー_v*_開発署名.apk' | Remove-Item -Force

Write-Output "配布用: $versioned"
Write-Output "ドライブ: $driveDir\$latestName （v$versionName）"
