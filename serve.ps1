# Local test server for the Receipts app: http://localhost:8765/
$root = $PSScriptRoot
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://localhost:8765/')
$listener.Start()
Write-Host "Serving $root on http://localhost:8765/"
$mime = @{ '.html' = 'text/html; charset=utf-8'; '.json' = 'application/json'; '.png' = 'image/png'; '.js' = 'text/javascript'; '.css' = 'text/css' }
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
  if (-not $rel) { $rel = 'index.html' }
  $path = [IO.Path]::GetFullPath((Join-Path $root $rel))
  if ($path.StartsWith($root) -and (Test-Path $path -PathType Leaf)) {
    $bytes = [IO.File]::ReadAllBytes($path)
    $type = $mime[[IO.Path]::GetExtension($path).ToLower()]
    if ($type) { $ctx.Response.ContentType = $type }
    $ctx.Response.Headers.Add('Cache-Control', 'no-store')
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
  }
  $ctx.Response.Close()
}
