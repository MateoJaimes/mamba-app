param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$projectRef = 'affhiuzxhejwolcoivnf'
$repoRoot = Split-Path $PSScriptRoot -Parent
$settings = @{
  site_url = 'https://mapo-experiencias-api.vercel.app/auth/callback'
  uri_allow_list = 'mapo://auth-callback,https://mapo-experiencias-api.vercel.app/auth/callback,https://mapo-experiencias-api.vercel.app/auth/callback?flow=signup,https://mapo-experiencias-api.vercel.app/auth/callback?flow=recovery,https://mapo-experiencias-api.vercel.app/auth/callback?flow=email_change'
  external_email_enabled = $true
  mailer_autoconfirm = $false
  mailer_secure_email_change_enabled = $true
  smtp_admin_email = 'somosmapoapp@gmail.com'
  smtp_host = 'smtp.gmail.com'
  smtp_port = '587'
  smtp_user = 'somosmapoapp@gmail.com'
  smtp_sender_name = 'MAPO'
}
$subjects = @{
  confirmation = 'Confirma tu correo y empieza a explorar con MAPO'
  recovery = 'Recupera tu acceso a MAPO'
  email_change = 'Confirma tu nuevo correo en MAPO'
  invite = 'Hay un lugar para ti en MAPO'
  magic_link = 'Tu enlace seguro para entrar a MAPO'
  reauthentication = 'Tu código de verificación de MAPO'
}
foreach ($item in $subjects.GetEnumerator()) {
  $settings["mailer_subjects_$($item.Key)"] = $item.Value
  $settings["mailer_templates_$($item.Key)_content"] = [IO.File]::ReadAllText((Join-Path $repoRoot "templates/$($item.Key).html"))
}
if (-not $Apply) {
  $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $repoRoot 'auth-settings.json') -Encoding utf8
  Write-Host 'Configuración sin contraseñas preparada en backend/auth-settings.json. Para aplicarla ejecuta npm run configure:auth desde backend.'
  return
}
# Credentials are typed locally, never saved to the repo or printed.
$localEnv = Join-Path $repoRoot '.env.local'
$localValues = @{}
if (Test-Path -LiteralPath $localEnv) {
  foreach ($line in [IO.File]::ReadAllLines($localEnv)) {
    if ($line -match '^([A-Z_]+)=(.*)$') { $localValues[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'") }
  }
}
$secureToken = if ($localValues.SUPABASE_MANAGEMENT_TOKEN) { ConvertTo-SecureString $localValues.SUPABASE_MANAGEMENT_TOKEN -AsPlainText -Force } else { Read-Host 'Token de administración de Supabase para la cuenta MAPO (entrada oculta)' -AsSecureString }
$securePassword = if ($localValues.SMTP_PASSWORD) { ConvertTo-SecureString $localValues.SMTP_PASSWORD -AsPlainText -Force } else { Read-Host 'Contraseña de aplicación de Gmail de somosmapoapp@gmail.com (entrada oculta)' -AsSecureString }
$tokenPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
  $accessToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPointer)
  $settings.smtp_pass = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer).Replace(' ', '')
  if ([string]::IsNullOrWhiteSpace($accessToken) -or [string]::IsNullOrWhiteSpace($settings.smtp_pass)) { throw 'Las credenciales no pueden estar vacías.' }
  $headers = @{ Authorization = "Bearer $accessToken" }
  $endpoint = "https://api.supabase.com/v1/projects/$projectRef/config/auth"
  Invoke-RestMethod -Uri $endpoint -Method Patch -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes(($settings | ConvertTo-Json -Depth 5))) | Out-Null
  $check = Invoke-RestMethod -Uri $endpoint -Headers $headers
  if ($check.site_url -ne $settings.site_url -or $check.smtp_user -ne 'somosmapoapp@gmail.com' -or $check.mailer_autoconfirm -ne $false -or $check.mailer_templates_confirmation_content -notmatch 'MAPO') { throw 'La comprobación de la configuración no pasó.' }
  Write-Host 'Configuración verificada: SMTP de MAPO, confirmación obligatoria y plantillas personalizadas.'
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPointer)
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
  $settings.Remove('smtp_pass')
  $accessToken = $null
  $headers = $null
  $securePassword.Dispose()
  $secureToken.Dispose()
}
