# Naver blog RSS -> blog.json (latest posts for the homepage "blog news" section)
# Usage: pwsh ./scripts/update-blog.ps1 [-Out blog.json] [-Count 3]
param([string]$Out = 'blog.json', [int]$Count = 3)
$ErrorActionPreference = 'Stop'

$rss = 'https://rss.blog.naver.com/djpark_kr.xml'
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('User-Agent', 'homepage-blog-feed')
$text = [System.Text.Encoding]::UTF8.GetString($wc.DownloadData($rss))
[xml]$xml = $text

$posts = @()
foreach ($item in ($xml.rss.channel.item | Select-Object -First $Count)) {
  $title = $item.SelectSingleNode('title').InnerText.Trim()
  $link = ($item.SelectSingleNode('link').InnerText.Trim() -split '\?')[0]
  $raw = $item.SelectSingleNode('pubDate').InnerText.Trim() -replace '([+-]\d\d)(\d\d)$', '$1:$2'
  $date = [DateTimeOffset]::ParseExact($raw, 'ddd, dd MMM yyyy HH:mm:ss zzz', [Globalization.CultureInfo]::InvariantCulture)
  $posts += [ordered]@{ title = $title; link = $link; date = $date.ToString('yyyy-MM-dd') }
}
if ($posts.Count -eq 0) { throw 'RSS has no posts' }

$json = ConvertTo-Json -InputObject ([ordered]@{ source = 'https://blog.naver.com/djpark_kr'; posts = $posts }) -Depth 4
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $Out), $json + "`n", (New-Object System.Text.UTF8Encoding $false))
"wrote $Out ($($posts.Count) posts)"
