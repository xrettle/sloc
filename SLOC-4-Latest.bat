@echo off
setlocal EnableDelayedExpansion
title SLOC v4
color 0b

:: =============================================================================
::  SLOC v4.0
::  ARCHITECT: xrettle
::  FEATURES:
::   - JIT PowerShell Worker Generation (Syntax-Safe)
::   - High-Performance .NET IO (System.IO)
::   - Smart Progress Tracking (Updates every 1k files to preserve speed)
::   - Large File Protection (>100MB skipped)
::   - Memory & CPU Optimized
:: =============================================================================

:ask_dir
cls
echo.
echo  =======================================================
echo   SLOC v4
echo  =======================================================
echo.
set "target_dir="
set /p "target_dir=Enter directory path to scan: "

:: --- PASS 3: SECURITY & INPUT VALIDATION ---
:: 1. Validation: Check if empty
if not defined target_dir goto :ask_dir

:: 2. Sanitization: Remove double quotes globally
set "target_dir=!target_dir:"=!"

:: 3. Sanitization: Remove trailing backslash to prevent CLI argument escape bugs
if "!target_dir:~-1!"=="\" set "target_dir=!target_dir:~0,-1!"

:: 4. Validation: Check existence
if not exist "!target_dir!" (
    echo.
    echo [ERROR] Directory not found: "!target_dir!"
    timeout /t 2 >nul
    goto :ask_dir
)

echo.
echo  [SYSTEM] Initializing scan engine...
echo  [STATUS] Target: "!target_dir!"
echo.

:: =============================================================================
::  GENERATE POWERSHELL WORKER
::  Strategy: Line-by-line append (>>) to ensure 100% syntax safety.
:: =============================================================================
set "ps_script=%temp%\fast_count_v4.ps1"
if exist "%ps_script%" del /f /q "%ps_script%"

:: --- HEADER & PARAMETERS ---
echo param([string]$targetPath) >> "%ps_script%"
echo $ErrorActionPreference = 'Stop' >> "%ps_script%"
echo $sw = [System.Diagnostics.Stopwatch]::StartNew() >> "%ps_script%"

:: --- EXTENSION DEFINITIONS (Optimized Array) ---
echo $exts = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase) >> "%ps_script%"
echo $list = @( >> "%ps_script%"
echo   '.c','.cpp','.h','.hpp','.cc','.cp','.cxx', >> "%ps_script%"
echo   '.cs','.css','.scss','.less','.sass','.styl', >> "%ps_script%"
echo   '.html','.htm','.xhtml','.vue','.svelte', >> "%ps_script%"
echo   '.js','.json','.jsx','.ts','.tsx','.mjs','.cjs', >> "%ps_script%"
echo   '.java','.kt','.kts','.groovy','.scala', >> "%ps_script%"
echo   '.py','.pyw','.rb','.pl','.php','.php4','.php5', >> "%ps_script%"
echo   '.sh','.bash','.zsh','.bat','.cmd','.ps1','.vbs', >> "%ps_script%"
echo   '.xml','.yaml','.yml','.toml','.ini','.conf','.cfg', >> "%ps_script%"
echo   '.sql','.md','.txt','.rtf','.log','.csv', >> "%ps_script%"
echo   '.go','.rs','.swift','.lua','.r','.dart','.elm' >> "%ps_script%"
echo ) >> "%ps_script%"
echo foreach ($e in $list) { $null = $exts.Add($e) } >> "%ps_script%"

:: --- PHASE 1: DISCOVERY (Count Total Files for Progress Bar) ---
echo try { >> "%ps_script%"
echo     Write-Host "  [1/2] Discovering files..." -NoNewline >> "%ps_script%"
echo     $files = [System.IO.Directory]::GetFiles($targetPath, "*.*", [System.IO.SearchOption]::AllDirectories) >> "%ps_script%"
echo     $totalFileCount = $files.Count >> "%ps_script%"
echo     Write-Host " Found $($totalFileCount.ToString('N0')) files." -ForegroundColor Gray >> "%ps_script%"
echo } catch { >> "%ps_script%"
echo     Write-Host "`n  [FATAL] Access denied or path invalid: $_" -ForegroundColor Red >> "%ps_script%"
echo     exit 1 >> "%ps_script%"
echo } >> "%ps_script%"

:: --- PHASE 2: PROCESSING (The Heavy Lift) ---
echo. >> "%ps_script%"
echo $processed = 0 >> "%ps_script%"
echo $codeFiles = 0 >> "%ps_script%"
echo $totalLines = 0 >> "%ps_script%"
echo $totalChars = 0 >> "%ps_script%"
echo $skippedLarge = 0 >> "%ps_script%"
echo $updateInterval = [Math]::Max(1, [Math]::Floor($totalFileCount / 100)) >> "%ps_script%"

echo foreach ($f in $files) { >> "%ps_script%"
echo     $processed++ >> "%ps_script%"
echo     $ext = [System.IO.Path]::GetExtension($f) >> "%ps_script%"
echo     if ([string]::IsNullOrWhiteSpace($ext)) { continue } >> "%ps_script%"
echo. >> "%ps_script%"
::       --- PERFORMANCE OPTIMIZATION: Update UI only 1% of the time ---
echo     if ($processed %% $updateInterval -eq 0) { >> "%ps_script%"
echo         $percent = [Math]::Round(($processed / $totalFileCount) * 100, 1) >> "%ps_script%"
echo         Write-Progress -Activity "Scanning Codebase" -Status "Processing: $f" -PercentComplete $percent -CurrentOperation "$processed / $totalFileCount files" >> "%ps_script%"
echo     } >> "%ps_script%"
echo. >> "%ps_script%"
echo     if ($exts.Contains($ext)) { >> "%ps_script%"
echo         try { >> "%ps_script%"
echo             $info = New-Object System.IO.FileInfo($f) >> "%ps_script%"
::               --- SAFETY: Skip >100MB files ---
echo             if ($info.Length -gt 104857600) { >> "%ps_script%"
echo                 $skippedLarge++ >> "%ps_script%"
echo                 continue >> "%ps_script%"
echo             } >> "%ps_script%"
::               --- MEMORY OPTIMIZATION: ReadAllText is faster than Get-Content ---
echo             $content = [System.IO.File]::ReadAllText($f) >> "%ps_script%"
echo             $totalChars += $content.Length >> "%ps_script%"
echo             if ($content.Length -gt 0) { >> "%ps_script%"
::               --- LOGIC: Fast Line Count (Len - LenNoNewLines + 1) ---
echo                 $totalLines += ($content.Length - $content.Replace("`n", "").Length) + 1 >> "%ps_script%"
echo             } >> "%ps_script%"
echo             $codeFiles++ >> "%ps_script%"
echo         } catch { >> "%ps_script%"
::               Silent catch for locked files to keep speed up >> "%ps_script%"
echo         } >> "%ps_script%"
echo     } >> "%ps_script%"
echo } >> "%ps_script%"
echo Write-Progress -Activity "Scanning Codebase" -Completed >> "%ps_script%"
echo $sw.Stop() >> "%ps_script%"

:: --- REPORTING ---
echo. >> "%ps_script%"
echo Write-Host " =======================================================" -ForegroundColor Cyan >> "%ps_script%"
echo Write-Host "  RESULTS" -ForegroundColor Cyan >> "%ps_script%"
echo Write-Host " =======================================================" -ForegroundColor Cyan >> "%ps_script%"
echo Write-Host "  Total Files Scanned : $(($totalFileCount).ToString('N0'))" >> "%ps_script%"
echo Write-Host "  Code/Text Files     : $(($codeFiles).ToString('N0'))" >> "%ps_script%"
echo Write-Host "  Lines of Code       : $(($totalLines).ToString('N0'))" -ForegroundColor Green >> "%ps_script%"
echo Write-Host "  Characters          : $(($totalChars).ToString('N0'))" >> "%ps_script%"
echo Write-Host " -------------------------------------------------------" -ForegroundColor DarkGray >> "%ps_script%"
echo if ($skippedLarge -gt 0) { >> "%ps_script%"
echo     Write-Host "  [WARN] Skipped Large: $skippedLarge (>100MB)" -ForegroundColor Yellow >> "%ps_script%"
echo } >> "%ps_script%"
echo Write-Host "  Time Taken          : $(($sw.Elapsed.TotalSeconds).ToString('N3')) seconds" -ForegroundColor Yellow >> "%ps_script%"
echo Write-Host " =======================================================" -ForegroundColor Cyan >> "%ps_script%"

:: =============================================================================
::  EXECUTE WORKER
::  -NoProfile: Skips loading user profile (Faster startup)
::  -ExecutionPolicy Bypass: Ensures script runs on restricted systems
:: =============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps_script%" "!target_dir!"

:: Cleanup
del /f /q "%ps_script%" >nul 2>&1

echo.
pause
goto :ask_dir
