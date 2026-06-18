# ffmpeg_kit_flutter_new 4.2.x Windows C API includes the wrong header path
# (ffmpeg_kit_flutter_new_full vs ffmpeg_kit_flutter_new).
$roots = @($env:PUB_CACHE, "$env:USERPROFILE\.pub-cache", "$env:LOCALAPPDATA\Pub\Cache") |
  Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$patched = $false
foreach ($root in $roots) {
  Get-ChildItem -Path (Join-Path $root 'hosted') -Recurse -Filter 'ffmpeg_kit_flutter_plugin_c_api.cpp' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like '*ffmpeg_kit_flutter_new*\windows\*' } |
    ForEach-Object {
      $content = Get-Content -LiteralPath $_.FullName -Raw
      $fixed = $content -replace 'ffmpeg_kit_flutter_new_full', 'ffmpeg_kit_flutter_new'
      if ($fixed -ne $content) {
        Set-Content -LiteralPath $_.FullName -Value $fixed -NoNewline
        Write-Host "[ok] patched $($_.FullName)"
      } else {
        Write-Host "[ok] already patched $($_.FullName)"
      }
      $patched = $true
    }
}

if (-not $patched) {
  Write-Warning "ffmpeg_kit_flutter_plugin_c_api.cpp not found in pub cache"
}
