@echo off
echo -----------------------------------------------------
echo  APPLYING GRIEVANCE UPDATE FIX
echo -----------------------------------------------------
echo.

cd %~dp0

echo 1. Applying server-side fix...
node apply_grievance_update_fix.js
if %ERRORLEVEL% NEQ 0 (
  echo.
  echo ERROR: Failed to apply server-side fix
  goto :error
)

echo.
echo 2. Testing fix...
node test_grievance_update.js
if %ERRORLEVEL% NEQ 0 (
  echo.
  echo WARNING: Test failed. You may need to check server logs.
) else (
  echo.
  echo SUCCESS: Test passed!
)

echo.
echo 3. All fixes applied. To use the fix:
echo    1. Start the server: node server.js
echo    2. Run the Flutter app
echo.
echo See GRIEVANCE_UPDATE_FIX.md for detailed information.
echo.

goto :end

:error
echo.
echo Fix application failed. Please check the errors above.
exit /b 1

:end
