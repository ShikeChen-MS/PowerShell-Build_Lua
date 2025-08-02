param (
    [Parameter(Mandatory = $true)]
    [string]$LuaRoot
)

# Locate the src folder
$LuaSrc = Join-Path $LuaRoot "src"

# Check if cl.exe is available
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Write-Host "❌ MSVC environment not detected. Please run this script from a 'Developer Command Prompt for Visual Studio'."
    exit 1
}

# Change to Lua source directory
Set-Location $LuaSrc

# Clean previous build artifacts
Remove-Item *.obj, lua.lib, lua.exe, luac.exe -ErrorAction SilentlyContinue

Write-Host "🔧 Compiling Lua core source files..."
cl /c /O2 /MT `
    lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c `
    lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c `
    ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c `
    liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c

Write-Host "📦 Creating static library lua.lib..."
lib *.obj /OUT:lua.lib

Write-Host "🚀 Building lua.exe (interpreter)..."
cl /O2 /MT lua.c lua.lib

Write-Host "🛠️ Building luac.exe (compiler)..."
cl /O2 /MT luac.c `
    lundump.c lobject.c lopcodes.c ldebug.c lstate.c lfunc.c lstring.c `
    lgc.c lmem.c ltable.c ltm.c lzio.c llex.c lcode.c lparser.c lvm.c `
    lapi.c lauxlib.c lua.lib

# Create output directories
$BuildDir = Join-Path $LuaRoot "build"
$HeadersDir = Join-Path $BuildDir "headers"
$LibDir = Join-Path $LuaRoot "build" "lib"

New-Item -ItemType Directory -Force -Path $BuildDir, $HeadersDir, $LibDir | Out-Null

# Copy executables
Copy-Item "$LuaSrc\lua.exe" -Destination $BuildDir
Copy-Item "$LuaSrc\luac.exe" -Destination $BuildDir

# Copy static library
Copy-Item "$LuaSrc\lua.lib" -Destination $LibDir

# Copy header files
Copy-Item "$LuaSrc\*.h" -Destination $HeadersDir

Write-Host "`n✅ Build complete."
Write-Host " - Static library: $LibDir\lua.lib"
Write-Host " - Executables:    $BuildDir\lua.exe, luac.exe"
Write-Host " - Headers:        $HeadersDir\*.h"
