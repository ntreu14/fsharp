@echo off

if /i "%1" == "debug" goto :ok
if /i "%1" == "release" goto :ok
if /i "%1" == "vsdebug" goto :ok
if /i "%1" == "vsrelease" goto :ok

echo Builds a few test tools using latest compiler and runtime
echo Usage:
echo    BuildTestTools.cmd debug
echo    BuildTestTools.cmd release
echo    BuildTestTools.cmd vsdebug
echo    BuildTestTools.cmd vsrelease
exit /b 1

:ok

:: Check prerequisites
if not '%VisualStudioVersion%' == '' goto vsversionset
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\common7\ide\devenv.exe" set VisualStudioVersion=14.0
if exist "%ProgramFiles%\Microsoft Visual Studio 14.0\common7\ide\devenv.exe" set VisualStudioVersion=14.0
if exist "%VS140COMNTOOLS%" set VisualStudioVersion=14.0

if not '%VisualStudioVersion%' == '' goto vsversionset
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 12.0\common7\ide\devenv.exe" set VisualStudioVersion=12.0
if exist "%ProgramFiles%\Microsoft Visual Studio 12.0\common7\ide\devenv.exe" set VisualStudioVersion=12.0
if exist "%VS120COMNTOOLS%" set VisualStudioVersion=12.0

:vsversionset
if '%VisualStudioVersion%' == '' echo Error: Could not find an installation of Visual Studio && goto :eof
if '%VisualStudioVersion%' == '14.0' (
	if exist "%ProgramFiles(x86)%\Microsoft SDKs\F#\4.0\Framework\v4.0\fsi.exe" set _fsiexe="%ProgramFiles(x86)%\Microsoft SDKs\F#\4.0\Framework\v4.0\fsi.exe"
)

if '%VisualStudioVersion%' == '12.0' (
	if exist "%ProgramFiles(x86)%\Microsoft SDKs\F#\3.1\Framework\v4.0\fsi.exe" set _fsiexe="%ProgramFiles(x86)%\Microsoft SDKs\F#\3.1\Framework\v4.0\fsi.exe"
)

if exist "%ProgramFiles(x86)%\MSBuild\%VisualStudioVersion%\Bin\MSBuild.exe" set _msbuildexe="%ProgramFiles(x86)%\MSBuild\%VisualStudioVersion%\Bin\MSBuild.exe"
if exist "%ProgramFiles%\MSBuild\%VisualStudioVersion%\Bin\MSBuild.exe"      set _msbuildexe="%ProgramFiles%\MSBuild\%VisualStudioVersion%\Bin\MSBuild.exe"
if not exist %_msbuildexe% echo Error: Could not find MSBuild.exe. && goto :eof

if not exist "%~dp0\fsharpqa\testenv\bin" mkdir "%~dp0\fsharpqa\testenv\bin"  || goto :error
%_msbuildexe% %~dp0\fsharpqa\testenv\src\ILComparer\ILComparer.fsproj /p:Configuration=%1 /t:Build  || goto :error
xcopy /Y %~dp0\fsharpqa\testenv\src\ILComparer\bin\%1\* %~dp0\fsharpqa\testenv\bin  || goto :error

%_msbuildexe% %~dp0\fsharpqa\testenv\src\diff\diff.fsproj /p:Configuration=%1 /t:Build  || goto :error
xcopy /Y %~dp0\fsharpqa\testenv\src\diff\bin\%1\* %~dp0\fsharpqa\testenv\bin  || goto :error

%_msbuildexe% %~dp0\fsharpqa\testenv\src\HostedCompilerServer\HostedCompilerServer.fsproj /p:Configuration=%1 /t:Build  || goto :error
xcopy /Y %~dp0\fsharpqa\testenv\src\HostedCompilerServer\bin\%1\* %~dp0\fsharpqa\testenv\bin  || goto :error

%_msbuildexe% %~dp0\fsharpqa\testenv\src\ExecAssembly\ExecAssembly.fsproj /p:Configuration=%1 /t:Build /p:Platform=x86  || goto :error
xcopy /IY %~dp0\fsharpqa\testenv\src\ExecAssembly\bin\%1\* %~dp0\fsharpqa\testenv\bin\x86  || goto :error

%_msbuildexe% %~dp0\fsharpqa\testenv\src\ExecAssembly\ExecAssembly.fsproj /p:Configuration=%1 /t:Build /p:Platform=x64  || goto :error
xcopy /IY %~dp0\fsharpqa\testenv\src\ExecAssembly\bin\%1\* %~dp0\fsharpqa\testenv\bin\AMD64  || goto :error

if exist %~dp0\..\%1\net40\bin (
    xcopy /Y %~dp0\..\%1\net40\bin\FSharp.Core.sigdata %~dp0\fsharpqa\testenv\bin  || goto :error
    xcopy /Y %~dp0\..\%1\net40\bin\FSharp.Core.optdata %~dp0\fsharpqa\testenv\bin  || goto :error
)

set NUNITPATH=%~dp0%..\packages\NUnit.Runners.2.6.4\tools\
if not exist "%NUNITPATH%" (
    pushd %~dp0..
    .\.nuget\nuget.exe restore packages.config -PackagesDirectory packages
    popd
)    
xcopy "%NUNITPATH%*.*"  "%~dp0\fsharpqa\testenv\bin\nunit\*.*" /S /Q /Y
xcopy "%~dp0\fsharpqa\testenv\src\nunit\*.*" "%~dp0\fsharpqa\testenv\bin\nunit\*.*" /S /Q /Y


set NUNITPATH=%~dp0%..\packages\NUnit.Runners.2.6.4\tools\
if not exist "%NUNITPATH%" (
    pushd %~dp0..
    .\.nuget\nuget.exe restore packages.config -PackagesDirectory packages
    popd
)    
xcopy "%NUNITPATH%*.*"  "%~dp0\fsharpqa\testenv\bin\nunit\*.*" /S /Q /Y
xcopy "%~dp0\fsharpqa\testenv\src\nunit\*.*" "%~dp0\fsharpqa\testenv\bin\nunit\*.*" /S /Q /Y

echo %_fsiexe%
rem deploy x86 version of compiler and dependencies
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/win7-x86 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\fsc\win7-x86 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:yes --v:quiet
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/win7-x86 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\win7-x86 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:no --v:quiet

rem deploy x64 version of compiler
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/win7-x64 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\fsc\win7-x64 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:yes --v:quiet
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/win7-x64 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\win7-x64 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:no --v:quiet

rem deploy linux version of built compiler
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/ubuntu.14.04-x64 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\fsc\ubuntu.14.04-x64 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:yes --v:quiet
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/win7-x64 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\ubuntu.14.04-x64 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:no --v:quiet

rem deploy osx version of built compiler
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/ubuntu.14.04-x64 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\fsc\osx.10.10-x64 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:yes --v:quiet
%_fsiexe% --exec %~dp0\fsharpqa\testenv\src\DeployProj\DeployProj.fsx --projectJson:%~dp0\fsharp\project.json --projectJsonLock:%~dp0\fsharp\project.lock.json --packagesDir:%~dp0\..\packages --targetPlatformName:DNXCore,Version=v5.0/win7-x64 --fsharpCore:%~dp0\..\%1\coreclr\bin\fsharp.core.dll --output:%~dp0\testbin\%1\coreclr\osx.10.10-x64 --nugetPath:%~dp0\..\.nuget\nuget.exe --nugetConfig:%~dp0\..\.nuget\nuget.config --copyCompiler:no --v:quiet

goto :EOF

:error
echo Failed with error %errorlevel%.
exit /b %errorlevel%
