@echo off
chcp 65001 >nul
set PYTHONIOENCODING=utf-8
title DQMJ2P Auto-Patcher JP (with Logging)

set LOGFILE=patch_log.txt

echo ============================================ | tee -a "%LOGFILE%"
echo   DQMJ2P Synthesis Patcher JP   | tee -a "%LOGFILE%"
echo ============================================ | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Checking for Pro_Tools\blz.exe... | tee -a "%LOGFILE%"
if not exist "Pro_Tools\blz.exe" (
    echo ERROR: blz.exe not found in Pro_Tools. | tee -a "%LOGFILE%"
    echo This file is required. Aborting. | tee -a "%LOGFILE%"
    pause
    exit /b
)
echo blz.exe found. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Checking for ndstool.exe... | tee -a "%LOGFILE%"
if not exist "ndstool.exe" (
    echo ERROR: ndstool.exe not found in the root directory. | tee -a "%LOGFILE%"
    echo This file is required. Aborting. | tee -a "%LOGFILE%"
    pause
    exit /b
)
echo ndstool.exe found. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Checking for DQMJ2P.nds... | tee -a "%LOGFILE%"
if not exist "DQMJ2P.nds" (
    echo ERROR: DQMJ2P.nds not found in the root directory. | tee -a "%LOGFILE%"
    echo This file is required. Aborting. | tee -a "%LOGFILE%"
    pause
    exit /b
)
echo DQMJ2P.nds found. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Creating Pro_ROM folder if missing... | tee -a "%LOGFILE%"
if not exist "Pro_ROM" mkdir "Pro_ROM" 2>&1 | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Extracting ROM contents with ndstool... | tee -a "%LOGFILE%"
ndstool -x DQMJ2P.nds ^
 -7 Pro_ROM\arm7.bin ^
 -9 Pro_ROM\arm9.bin ^
 -d Pro_ROM\data ^
 -y Pro_ROM\overlay ^
 -t Pro_ROM\banner.bin ^
 -h Pro_ROM\header.bin ^
 -y7 Pro_ROM\y7.bin ^
 -y9 Pro_ROM\y9.bin 2>&1 | tee -a "%LOGFILE%"

echo Extraction complete. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Decompressing ARM9... | tee -a "%LOGFILE%"
python Pro_Tools\arm9tool.py decompress Pro_ROM\arm9.bin Pro_Tools\Pro_ARM9.bin 2>&1 | tee -a "%LOGFILE%"
echo ARM9 decompressed. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Parsing synthesis tables... | tee -a "%LOGFILE%"
python Pro_Tools\synthesis_parser.py --in Pro_ROM\data\CombinationKindTbl.bin --out Kind.csv 2>&1 | tee -a "%LOGFILE%"
python Pro_Tools\synthesis_parser.py --in Pro_ROM\data\Combination4GTbl.bin --out 4g.csv --type 4g 2>&1 | tee -a "%LOGFILE%"

echo Merging new synthesis entries... | tee -a "%LOGFILE%"
python -c "from pathlib import Path; open('Kind.csv','a',encoding='utf-8',newline='').write(Path('Database/new_synths_kind.csv').read_text(encoding='utf-8'))" 2>&1 | tee -a "%LOGFILE%"
python -c "from pathlib import Path; open('4g.csv','a',encoding='utf-8',newline='').write(Path('Database/new_synths_4g.csv').read_text(encoding='utf-8'))" 2>&1 | tee -a "%LOGFILE%"


echo Rebuilding synthesis tables... | tee -a "%LOGFILE%"
python Pro_Tools\synthesis_parser.py --in Kind.csv --out Pro_ROM\data\CombinationKindTbl.bin 2>&1 | tee -a "%LOGFILE%"
python Pro_Tools\synthesis_parser.py --in 4g.csv --out Pro_ROM\data\Combination4GTbl.bin --type 4g 2>&1 | tee -a "%LOGFILE%"

echo Synthesis tables updated. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo Rebuilding patched ROM... | tee -a "%LOGFILE%"
ndstool -c Patched.nds ^
 -7 Pro_ROM\arm7.bin ^
 -9 Pro_ROM\arm9.bin ^
 -d Pro_ROM\data ^
 -y Pro_ROM\overlay ^
 -t Pro_ROM\banner.bin ^
 -h Pro_ROM\header.bin ^
 -y7 Pro_ROM\y7.bin ^
 -y9 Pro_ROM\y9.bin 2>&1 | tee -a "%LOGFILE%"

echo. | tee -a "%LOGFILE%"

echo Cleaning up temporary files... | tee -a "%LOGFILE%"

del "4g.csv" 2>&1 | tee -a "%LOGFILE%"
del "Kind.csv" 2>&1 | tee -a "%LOGFILE%"
del "Pro_Tools\Pro_ARM9.bin" 2>&1 | tee -a "%LOGFILE%"
if exist "Pro_Tools\__pycache__" rmdir /s /q "Pro_Tools\__pycache__" 2>&1 | tee -a "%LOGFILE%"
if exist "Pro_ROM" rmdir /s /q "Pro_ROM" 2>&1 | tee -a "%LOGFILE%"

echo Cleanup complete. | tee -a "%LOGFILE%"
echo. | tee -a "%LOGFILE%"

echo ============================================ | tee -a "%LOGFILE%"
echo   DONE! Patched.nds has been created.        | tee -a "%LOGFILE%"
echo   Full log saved to patch_log.txt            | tee -a "%LOGFILE%"
echo ============================================ | tee -a "%LOGFILE%"
pause
