@echo off

rem Echo a single line describing the state of the working copy.
rem %1 should be the path to git
rem %2 should be the output filename

rem The pattern (echo.|set /p="str") allows echoing "str" without a line break.

setlocal

for /F %%C in ('%1 rev-parse --verify HEAD') do (echo.|set /p="%%C") >%2

$1 diff-index --quiet HEAD
if not errorlevel 1 (echo.|set /p=", plus uncommitted changes") >>%2

for /F "delims=" %%C in ('%1 rev-parse --show-cdup') do (
    %1 ls-files --others --exclude-standard --error-unmatch "./%%C" >nul 2>&1
    if errorlevel 1 (echo.|set /p=", plus untracked files") >>%2
)
