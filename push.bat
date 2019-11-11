git add .
@echo off
set /p id="Enter commit details: "
git commit -m "%id%"
git push origin master
doskey /history
pause