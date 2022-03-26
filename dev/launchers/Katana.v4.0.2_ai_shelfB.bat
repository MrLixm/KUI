:: Katana launcher script
:: Made for test of KUI
@echo on

set "U_KATANA_VERSION=4.0v2"
set "U_KATANA_HOME=C:\Program Files\Katana%U_KATANA_VERSION%"

set "DEFAULT_RENDERER=arnold"
set "KATANA_TAGLINE=Arnold 4.0.0.0"

set "PATH=%PATH%;%U_KATANA_HOME%\bin";
set KATANA_CATALOG_RECT_UPDATE_BUFFER_SIZE=1
set "KATANA_USER_RESOURCE_DIRECTORY=%~dp0..\prefs\shelfB\prefs"

set "LUA_PATH=%LUA_PATH%;%~dp0..\prefs\shelfB\lua\?.lua"

:: Arnold config
set "U_KTOA_VERSION=ktoa-4.0.0.0-kat4.0-windows"
set "U_KTOA_HOME=C:\Users\lcoll\ktoa\%U_KTOA_VERSION%"
set "ARNOLD_PLUGIN_PATH=%U_KTOA_HOME%\Plugins"
set "PATH=%PATH%;%U_KTOA_HOME%\bin"
set "KATANA_RESOURCES=%KATANA_RESOURCES%;%U_KTOA_HOME%"

:: Xgen configuration
set "MAYA_INSTALLATION=C:\Program Files\Autodesk\Maya2020"
set "XGEN_LOCATION=%MAYA_INSTALLATION%\plug-ins\xgen"
set "PATH=%PATH%;%XGEN_LOCATION%;%XGEN_LOCATION%\bin;%MAYA_INSTALLATION%\bin;"

start "" "%U_KATANA_HOME%\bin\katanaBin.exe"
