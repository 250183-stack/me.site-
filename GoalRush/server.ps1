param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$rootPath = [System.IO.Path]::GetFullPath($PSScriptRoot)
$rootPrefix = $rootPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
$contentTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.css' = 'text/css; charset=utf-8'
    '.js' = 'text/javascript; charset=utf-8'
    '.png' = 'image/png'
    '.jpg' = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.jfif' = 'image/jpeg'
    '.webp' = 'image/webp'
    '.avif' = 'image/avif'
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "GoaLRush started: http://localhost:$Port/"
    Write-Host 'Offline rosters are ready. Press Ctrl+C to stop.'

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            if ($request.HttpMethod -ne 'GET') {
                $response.StatusCode = 405
                continue
            }

            $relativePath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart('/'))
            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                $relativePath = [System.Uri]::UnescapeDataString('%D0%BF%D1%89%D1%80.html')
            }

            $filePath = [System.IO.Path]::GetFullPath((Join-Path $rootPath $relativePath))
            if (-not $filePath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                $response.StatusCode = 404
                continue
            }

            $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
            if (-not $contentTypes.ContainsKey($extension)) {
                $response.StatusCode = 404
                continue
            }

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentTypes[$extension]
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        finally {
            $response.Close()
        }
    }
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}
