@echo off
echo ==========================================
echo  Remove Background - All Images in shots/
echo ==========================================
echo.

set TOOLS=%~dp0
set SHOTS=%TOOLS%..\shots
set OUTPUT=%TOOLS%..\shots_processed

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

echo Processing all images...
echo.

for /r "%SHOTS%" %%f in (*.png *.jpg *.jpeg *.webp) do (
    echo Processing: %%~nxf
    python "%TOOLS%remove_bg.py" "%%f" "%OUTPUT%\%%~nf_nobg.png"
    if exist "%OUTPUT%\%%~nf_nobg.png" (
        echo   - Background removed: %%~nf_nobg.png
    ) else (
        echo   - FAILED: %%~nxf
    )
    echo.
)

echo ==========================================
echo  Done! Check: %OUTPUT%
echo ==========================================
pause
