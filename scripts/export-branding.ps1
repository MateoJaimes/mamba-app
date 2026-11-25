$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$symbol = [Drawing.Image]::FromFile((Join-Path $root 'assets/branding/mapo-symbol.png'))
$appIcon = [Drawing.Image]::FromFile((Join-Path $root 'assets/branding/mapo-icon.png'))
function Export-Icon([string]$relativePath, [int]$size, [double]$scale = 1.0, [Drawing.Image]$artwork = $appIcon, [switch]$Transparent) {
  $destination = Join-Path $root $relativePath
  [IO.Directory]::CreateDirectory((Split-Path $destination -Parent)) | Out-Null
  $bitmap = [Drawing.Bitmap]::new($size, $size, $(if ($Transparent) { [Drawing.Imaging.PixelFormat]::Format32bppArgb } else { [Drawing.Imaging.PixelFormat]::Format24bppRgb }))
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  try {
    if (-not $Transparent) { $graphics.Clear([Drawing.ColorTranslator]::FromHtml('#0E1B34')) }
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $edge = [int][Math]::Round($size * $scale)
    $height = [int][Math]::Round($edge * $artwork.Height / $artwork.Width)
    $offsetX = [int](($size - $edge) / 2)
    $offsetY = [int](($size - $height) / 2)
    $graphics.DrawImage($artwork, [Drawing.Rectangle]::new($offsetX, $offsetY, $edge, $height))
    $bitmap.Save($destination, [Drawing.Imaging.ImageFormat]::Png)
  } finally { $graphics.Dispose(); $bitmap.Dispose() }
}
try {
  $densities = @(@('mdpi',1),@('hdpi',1.5),@('xhdpi',2),@('xxhdpi',3),@('xxxhdpi',4))
  foreach($entry in $densities) {
    $density = $entry[0]; $factor = [double]$entry[1]
    Export-Icon "android/app/src/main/res/mipmap-$density/ic_launcher.png" ([int](48*$factor))
    Export-Icon "android/app/src/main/res/drawable-$density/mapo_foreground.png" ([int](108*$factor)) 0.6 $symbol -Transparent
    Export-Icon "android/app/src/main/res/drawable-$density/mapo_splash.png" ([int](192*$factor)) 0.58 $symbol -Transparent
  }
  $catalog = Get-Content -Raw (Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') | ConvertFrom-Json
  foreach($entry in $catalog.images) {
    $size = [int]([double]($entry.size.Split('x')[0]) * [double]($entry.scale.Replace('x','')))
    Export-Icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" $size
  }
  Export-Icon 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png' 168 0.7  -Transparent
  Export-Icon 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png' 336 0.7  -Transparent
  Export-Icon 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png' 504 0.7  -Transparent
  Export-Icon 'web/favicon.png' 64
  foreach($size in @(192,512)) {
    Export-Icon "web/icons/Icon-$size.png" $size
    Export-Icon "web/icons/Icon-maskable-$size.png" $size 0.85
  }
  Export-Icon 'backend/public/branding/mapo-icon.png' 512
  Write-Host 'Iconos exportados: Android, iOS, web y backend. Solo simbolo, sin texto.'
} finally { $symbol.Dispose(); $appIcon.Dispose() }
