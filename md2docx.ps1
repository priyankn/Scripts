#requires -Version 5.1
<#
Converts a Markdown letter to .docx via Word COM. Requires Microsoft Word installed.
Supports: ## headings, > blockquotes, **bold**. Skips # H1 titles and --- rules.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [string]$OutputPath,

    [string]$FontName = 'Calibri',

    [double]$FontSize = 11
)

$ErrorActionPreference = 'Stop'

$src = (Resolve-Path -LiteralPath $Path).Path
if (-not $OutputPath) {
    $OutputPath = [System.IO.Path]::ChangeExtension($src, '.docx')
}
$out = [System.IO.Path]::GetFullPath($OutputPath)

$lines = Get-Content -LiteralPath $src -Encoding UTF8

$word = New-Object -ComObject Word.Application
$word.Visible = $false

try {
    $doc = $word.Documents.Add()

    $ps = $doc.PageSetup
    $ps.TopMargin = 72
    $ps.BottomMargin = 72
    $ps.LeftMargin = 72
    $ps.RightMargin = 72

    $sel = $word.Selection

    function Set-BaseFormat {
        $sel.Font.Name = $FontName
        $sel.Font.Size = $FontSize
        $sel.Font.Bold = 0
        $sel.Font.Italic = 0
        $sel.ParagraphFormat.Alignment = 0
        $sel.ParagraphFormat.LeftIndent = 0
        $sel.ParagraphFormat.RightIndent = 0
        $sel.ParagraphFormat.SpaceBefore = 0
        $sel.ParagraphFormat.SpaceAfter = 10
        $sel.ParagraphFormat.LineSpacingRule = 0
    }

    function Write-Inline([string]$text) {
        $parts = $text -split '\*\*'
        for ($i = 0; $i -lt $parts.Count; $i++) {
            if ($parts[$i] -eq '') { continue }
            if ($i % 2 -eq 1) { $sel.Font.Bold = 1 } else { $sel.Font.Bold = 0 }
            $sel.TypeText($parts[$i])
        }
        $sel.Font.Bold = 0
    }

    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t -eq '') { continue }
        if ($t -eq '---') { continue }
        if ($t -match '^#\s') { continue }

        Set-BaseFormat

        if ($t -match '^##\s+(.*)$') {
            $sel.Font.Size = $FontSize + 1
            $sel.Font.Bold = 1
            $sel.ParagraphFormat.SpaceBefore = 14
            $sel.ParagraphFormat.SpaceAfter = 6
            $sel.TypeText($Matches[1])
            $sel.TypeParagraph()
            continue
        }

        if ($t -match '^>\s*(.*)$') {
            $sel.Font.Italic = 1
            $sel.ParagraphFormat.LeftIndent = 36
            $sel.ParagraphFormat.RightIndent = 36
            Write-Inline $Matches[1]
            $sel.TypeParagraph()
            continue
        }

        Write-Inline $t
        $sel.TypeParagraph()
    }

    # 16 = wdFormatDocumentDefault (.docx)
    $doc.SaveAs2($out, 16)
    $doc.Close()

    Write-Output "SAVED: $out"
}
finally {
    $word.Quit()
}
