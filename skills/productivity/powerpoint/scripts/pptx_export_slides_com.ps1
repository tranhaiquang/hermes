param(
  [Parameter(Mandatory=$true)][string]$Spec,   # JSON file: [{"src":"<deck.pptx>","out":"<outdir>"}, ...]
  [int]$Scale = 2
)
$ErrorActionPreference = 'Stop'
$items = Get-Content -Raw -Path $Spec | ConvertFrom-Json
foreach ($f in $items) {
  if (-not (Test-Path $f.out)) { New-Item -ItemType Directory -Path $f.out -Force | Out-Null }
  $pp = New-Object -ComObject PowerPoint.Application
  try {
    # ReadOnly(msoTrue=-1), Untitled(0), WithWindow(msoFalse=0)
    $pres = $pp.Presentations.Open($f.src, -1, 0, 0)
    $w = [int]($pres.PageSetup.SlideWidth  * $Scale * 96 / 72)  # points -> pixels
    $h = [int]($pres.PageSetup.SlideHeight * $Scale * 96 / 72)
    $i = 1; $n = $pres.Slides.Count
    foreach ($slide in $pres.Slides) {
      $path = Join-Path $f.out ('slide-{0:D2}.png' -f $i)
      $slide.Export($path, 'PNG', $w, $h)
      Write-Output ("OK " + $i + "/" + $n + " -> " + $path)
      $i++
    }
    $pres.Close()
  } finally {
    $pp.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($pp) | Out-Null
  }
}
