param(
  [ValidateSet('patch','minor','major')]
  [string]$Level = 'patch'
)

$pubspec = "c:\Users\miska\smart-tres\darts\tresdarts_kiosk\pubspec.yaml"
$content = Get-Content $pubspec -Raw

$pattern = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$m = [regex]::Match($content, $pattern)
if (-not $m.Success) {
  throw "Version-riviä ei löytynyt pubspec.yaml:stä (odotettu muoto: x.y.z+build)."
}

$major = [int]$m.Groups[1].Value
$minor = [int]$m.Groups[2].Value
$patch = [int]$m.Groups[3].Value
$build = [int]$m.Groups[4].Value

switch ($Level) {
  'major' { $major += 1; $minor = 0; $patch = 0 }
  'minor' { $minor += 1; $patch = 0 }
  'patch' { $patch += 1 }
}

$build += 1
$newLine = "version: $major.$minor.$patch+$build"
$updated = [regex]::Replace($content, $pattern, $newLine, 1)
Set-Content $pubspec -Value $updated -Encoding UTF8

Write-Host $newLine -ForegroundColor Green

