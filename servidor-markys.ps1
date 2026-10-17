# MARKYS local HTTP server - Windows PowerShell 5.1+
$ErrorActionPreference = "Stop"
$Port = 2222
$PortCandidates = @(2222)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataFile = Join-Path $Root "fila.json"
$MediaFile = Join-Path $Root "midia.json"
$ProfessionalsFile = Join-Path $Root "profissionais.json"
$RecordsFile = Join-Path $Root "prontuarios.json"
$SlideshowDir = Join-Path $Root "midia-sala"
if (-not (Test-Path $SlideshowDir)) { New-Item -ItemType Directory -Path $SlideshowDir | Out-Null }
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path $DataFile)) { [System.IO.File]::WriteAllText($DataFile, "[]", $Utf8NoBom) }
if (-not (Test-Path $MediaFile)) { [System.IO.File]::WriteAllText($MediaFile, '{"url":""}', $Utf8NoBom) }
if (-not (Test-Path $ProfessionalsFile)) { [System.IO.File]::WriteAllText($ProfessionalsFile, "[]", $Utf8NoBom) }
if (-not (Test-Path $RecordsFile)) { [System.IO.File]::WriteAllText($RecordsFile, "[]", $Utf8NoBom) }
$listener = $null
foreach ($candidatePort in $PortCandidates) {
  $candidate = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $candidatePort)
  try {
    $candidate.Start()
    $listener = $candidate
    $Port = $candidatePort
    break
  } catch [System.Net.Sockets.SocketException] {
    $candidate.Stop()
  }
}
if ($null -eq $listener) {
  Write-Host "ERRO: a porta fixa 2222 não está disponível." -ForegroundColor Red
  Write-Host "Feche outra instância do MARKYS ou libere a porta 2222 e tente novamente."
  exit 1
}
try {
  Write-Host ""
  Write-Host "===============================================" -ForegroundColor Cyan
  Write-Host " MARKYS - Servidor da rede local" -ForegroundColor Cyan
  Write-Host "===============================================" -ForegroundColor Cyan
  Write-Host "Recepcao: http://127.0.0.1:$Port/"
  Write-Host "Tela sala de espera: http://127.0.0.1:$Port/?painel=1"
  Write-Host "Painel do profissional: http://127.0.0.1:$Port/consultorio"
  Write-Host "Atendimento medico:     http://127.0.0.1:$Port/atendimento"
  Write-Host "Triagem / sinais vitais: http://127.0.0.1:$Port/preparo"
  Write-Host ""
  Write-Host "Enderecos para outros dispositivos:" -ForegroundColor Yellow
  $ips = @()
  # Reune os IPv4 de todas as interfaces ativas, com ou sem gateway.
  try {
    $ips += Get-NetIPConfiguration -ErrorAction Stop |
      Where-Object { $_.NetAdapter.Status -eq "Up" -and $_.IPv4Address } |
      ForEach-Object { $_.IPv4Address } |
      Where-Object { $_.IPAddress -and $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
      ForEach-Object { $_.IPAddress }
  } catch { }
  # Tambem consulta as interfaces de rede para incluir adaptadores que o cmdlet nao retornou.
  try {
    $ips += [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
      Where-Object { $_.OperationalStatus -eq "Up" -and $_.NetworkInterfaceType -ne "Loopback" } |
      ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
      Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and $_.Address.ToString() -notlike "169.254.*" -and $_.Address.ToString() -notlike "127.*" } |
      ForEach-Object { $_.Address.ToString() }
  } catch { }
  $ips = @($ips | Select-Object -Unique)
  if ($ips.Count -eq 0) {
    Write-Host "AVISO: nao consegui detectar um IPv4 da rede. Verifique se o computador esta conectado ao Wi-Fi ou cabo." -ForegroundColor Yellow
  } else {
    foreach ($ip in $ips) {
      Write-Host ("Recepcao:      http://{0}:{1}/" -f $ip, $Port)
      Write-Host ("Sala de espera: http://{0}:{1}/?painel=1" -f $ip, $Port)
      Write-Host ("Profissional:  http://{0}:{1}/consultorio" -f $ip, $Port)
      Write-Host ("Atendimento:   http://{0}:{1}/atendimento" -f $ip, $Port)
      Write-Host ("Triagem:       http://{0}:{1}/preparo" -f $ip, $Port)
      Write-Host ""
    }
  }
  # Abre automaticamente o sistema no navegador da recepcao.
  try { Start-Process ("http://127.0.0.1:{0}/" -f $Port) } catch { Write-Host "Abra manualmente o endereco local mostrado acima." -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "Mantenha esta janela aberta. Pressione Ctrl+C para encerrar." -ForegroundColor Green
  while ($listener.Server.IsBound) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $stream.ReadTimeout = 5000
      $headerList = New-Object 'System.Collections.Generic.List[byte]'
      $ending = 0
      while ($headerList.Count -lt 16384) {
        $b = $stream.ReadByte()
        if ($b -lt 0) { break }
        $headerList.Add([byte]$b)
        if (($ending -eq 0 -and $b -eq 13) -or ($ending -eq 2 -and $b -eq 13)) { $ending++ }
        elseif (($ending -eq 1 -and $b -eq 10) -or ($ending -eq 3 -and $b -eq 10)) { $ending++ }
        else { $ending = 0 }
        if ($ending -ge 4) { break }
      }
      if ($headerList.Count -eq 0) { continue }
      $headerText = [System.Text.Encoding]::ASCII.GetString($headerList.ToArray())
      $lines = $headerText -split "`r`n"
      $request = $lines[0] -split " "
      if ($request.Count -lt 2) { continue }
      $method = $request[0].ToUpperInvariant()
      $requestTarget = $request[1]
      $path = $requestTarget.Split('?')[0]
      $contentLength = 0
      foreach ($line in $lines) { if ($line -match "(?i)^Content-Length:\s*(\d+)") { $contentLength = [int]$Matches[1] } }
      $bodyBytes = New-Object byte[] $contentLength
      $read = 0
      while ($read -lt $contentLength) {
        $n = $stream.Read($bodyBytes, $read, $contentLength - $read)
        if ($n -le 0) { break }
        $read += $n
      }
      $status = "200 OK"; $type = "text/plain; charset=utf-8"; $responseBytes = [byte[]]@()
      if ($path -eq "/api/slideshow" -and $method -eq "GET") {
        $items = @()
        foreach ($file in (Get-ChildItem -LiteralPath $SlideshowDir -File | Sort-Object Name)) {
          $ext = $file.Extension.ToLowerInvariant()
          $kind = if ($ext -in @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp")) { "image" } else { "video" }
          $items += @{ name = $file.Name; type = $kind; url = "/slideshow/" + [Uri]::EscapeDataString($file.Name) }
        }
        $jsonItems = ConvertTo-Json -InputObject @($items) -Compress -Depth 4
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonItems); $type = "application/json; charset=utf-8"
      } elseif ($path -eq "/api/slideshow/upload" -and $method -eq "POST") {
        if ($contentLength -gt 524288000 -or $read -ne $contentLength) { $status = "413 Payload Too Large"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Arquivo maior que 500 MB"}'); $type = "application/json; charset=utf-8" }
        else {
          try {
            $query = ""
            if ($requestTarget.Contains("?")) { $query = $requestTarget.Substring($requestTarget.IndexOf("?") + 1) }
            $rawName = ""
            foreach ($part in ($query -split "&")) { if ($part -match "^name=(.*)$") { $rawName = [Uri]::UnescapeDataString($Matches[1].Replace("+", " ")) } }
            $safeName = [System.IO.Path]::GetFileName($rawName)
            $ext = [System.IO.Path]::GetExtension($safeName).ToLowerInvariant()
            $allowed = @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".mp4", ".webm", ".ogg", ".mov", ".m4v")
            if ([string]::IsNullOrWhiteSpace($safeName) -or $safeName.Length -gt 180 -or $ext -notin $allowed -or $contentLength -le 0) { throw "Nome, extensão ou tamanho inválido" }
            $destination = Join-Path $SlideshowDir $safeName
            [System.IO.File]::WriteAllBytes($destination, $bodyBytes)
            $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}'); $type = "application/json; charset=utf-8"
          } catch { $status = "400 Bad Request"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Arquivo inválido. Use JPG, PNG, GIF, WEBP, BMP, MP4, WEBM, OGG, MOV ou M4V; máximo 500 MB."}'); $type = "application/json; charset=utf-8" }
        }
      } elseif ($path.StartsWith("/slideshow/")) {
        try {
          $requestedName = [Uri]::UnescapeDataString($path.Substring("/slideshow/".Length))
          $safeName = [System.IO.Path]::GetFileName($requestedName)
          $filePath = Join-Path $SlideshowDir $safeName
          if ([string]::IsNullOrWhiteSpace($safeName) -or -not (Test-Path -LiteralPath $filePath -PathType Leaf)) { throw "Not found" }
          $ext = [System.IO.Path]::GetExtension($safeName).ToLowerInvariant()
          $mime = @{ ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".png"="image/png"; ".gif"="image/gif"; ".webp"="image/webp"; ".bmp"="image/bmp"; ".mp4"="video/mp4"; ".webm"="video/webm"; ".ogg"="video/ogg"; ".mov"="video/quicktime"; ".m4v"="video/mp4" }
          $type = $mime[$ext]
          if (-not $type) { throw "Unsupported media type" }
          $responseBytes = [System.IO.File]::ReadAllBytes($filePath)
        } catch { $status = "404 Not Found"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Not found") }
      } elseif ($path -eq "/api/media" -and $method -eq "GET") {
        $responseBytes = [System.IO.File]::ReadAllBytes($MediaFile); $type = "application/json; charset=utf-8"
      } elseif ($path -eq "/api/media" -and $method -eq "POST") {
        if ($contentLength -gt 16384 -or $read -ne $contentLength) { $status = "413 Payload Too Large"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Payload too large") }
        else {
          try {
            $media = ConvertFrom-Json -InputObject ([System.Text.Encoding]::UTF8.GetString($bodyBytes))
            if ($null -eq $media -or $media -is [System.Array] -or $null -eq $media.url) { throw "Expected media URL" }
            $mediaUrl = [string]$media.url
            if ($mediaUrl.Length -gt 2048) { throw "URL too long" }
            $savedMedia = @{ url = $mediaUrl } | ConvertTo-Json -Compress
            [System.IO.File]::WriteAllText($MediaFile, $savedMedia, $Utf8NoBom)
            $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}'); $type = "application/json; charset=utf-8"
          } catch { $status = "400 Bad Request"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"invalid media"}'); $type = "application/json; charset=utf-8" }
        }
      } elseif ($path -eq "/api/state" -and $method -eq "GET") {
        $responseBytes = [System.IO.File]::ReadAllBytes($DataFile); $type = "application/json; charset=utf-8"
      } elseif ($path -eq "/api/state" -and $method -eq "POST") {
        if ($contentLength -gt 1048576 -or $read -ne $contentLength) { $status = "413 Payload Too Large"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Payload too large") }
        else {
          $json = [System.Text.Encoding]::UTF8.GetString($bodyBytes)
          try {
            $parsed = ConvertFrom-Json -InputObject $json
            if ($parsed -isnot [System.Array] -and $null -ne $parsed) { throw "Expected JSON array" }
            [System.IO.File]::WriteAllText($DataFile, $json, $Utf8NoBom)
            $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}'); $type = "application/json; charset=utf-8"
          } catch { $status = "400 Bad Request"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"invalid JSON"}'); $type = "application/json; charset=utf-8" }
        }
      } elseif ($path -eq "/api/professionals" -and $method -eq "GET") {
        $responseBytes = [System.IO.File]::ReadAllBytes($ProfessionalsFile); $type = "application/json; charset=utf-8"
      } elseif ($path -eq "/api/professionals" -and $method -eq "POST") {
        if ($contentLength -gt 262144 -or $read -ne $contentLength) { $status = "413 Payload Too Large"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Payload too large") }
        else {
          try {
            $json = [System.Text.Encoding]::UTF8.GetString($bodyBytes)
            if (-not $json.TrimStart().StartsWith("[")) { throw "Expected JSON array" }
            $null = ConvertFrom-Json -InputObject $json -ErrorAction Stop
            [System.IO.File]::WriteAllText($ProfessionalsFile, $json, $Utf8NoBom)
            $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}'); $type = "application/json; charset=utf-8"
          } catch {
            $status = "400 Bad Request"
            $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"invalid JSON array"}')
            $type = "application/json; charset=utf-8"
          }
        }
      } elseif ($path -eq "/api/records" -and $method -eq "GET") {
        $responseBytes = [System.IO.File]::ReadAllBytes($RecordsFile); $type = "application/json; charset=utf-8"
      } elseif ($path -eq "/api/records" -and $method -eq "POST") {
        if ($contentLength -gt 1048576 -or $read -ne $contentLength) { $status = "413 Payload Too Large"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Payload too large") }
        else { try { $json = [System.Text.Encoding]::UTF8.GetString($bodyBytes); $parsed = ConvertFrom-Json -InputObject $json; if ($parsed -isnot [System.Array] -and $null -ne $parsed) { throw "Expected JSON array" }; [System.IO.File]::WriteAllText($RecordsFile, $json, $Utf8NoBom); $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}'); $type = "application/json; charset=utf-8" } catch { $status = "400 Bad Request"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"invalid JSON"}'); $type = "application/json; charset=utf-8" } }
      } elseif ($path -eq "/" -or $path -eq "/index.html") {
        $responseBytes = [System.IO.File]::ReadAllBytes((Join-Path $Root "index.html")); $type = "text/html; charset=utf-8"
      } elseif ($path -eq "/consultorio" -or $path -eq "/consultorio.html") {
        $responseBytes = [System.IO.File]::ReadAllBytes((Join-Path $Root "consultorio.html")); $type = "text/html; charset=utf-8"
      } elseif ($path -eq "/preparo" -or $path -eq "/preparo.html") {
        $responseBytes = [System.IO.File]::ReadAllBytes((Join-Path $Root "preparo.html")); $type = "text/html; charset=utf-8"
      } elseif ($path -eq "/atendimento" -or $path -eq "/atendimento.html") {
        $responseBytes = [System.IO.File]::ReadAllBytes((Join-Path $Root "atendimento.html")); $type = "text/html; charset=utf-8"
      } elseif ($path -eq "/logo-Markys.png" -and (Test-Path (Join-Path $Root "logo-Markys.png"))) {
        $responseBytes = [System.IO.File]::ReadAllBytes((Join-Path $Root "logo-Markys.png")); $type = "image/png"
      } elseif ($path -eq "/sala-espera" -or $path -eq "/sala") {
        $status = "302 Found"; $type = "text/plain; charset=utf-8"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Abra /?painel=1")
      } elseif ($path -eq "/favicon.ico") {
        $status = "204 No Content"; $responseBytes = [byte[]]@()
      } else {
        $status = "404 Not Found"; $responseBytes = [System.Text.Encoding]::UTF8.GetBytes("Not found")
      }
      $header = "HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $($responseBytes.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n"
      if ($status -eq "302 Found") { $header += "Location: /?painel=1`r`n" }
      $header += "`r`n"
      $headBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headBytes, 0, $headBytes.Length)
      if ($responseBytes.Length -gt 0) { $stream.Write($responseBytes, 0, $responseBytes.Length) }
      $stream.Flush()
    } catch {
      Write-Host ("Erro ao atender requisicao: " + $_.Exception.Message) -ForegroundColor Red
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
