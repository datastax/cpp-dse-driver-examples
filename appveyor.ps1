<#
  Copyright (c) DataStax, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
#>

Function Get-Commit-Sha {
  return $($Env:APPVEYOR_REPO_COMMIT.SubString(0,7))
}

Function Get-Latest-Version ($Url) {
  Return ((Invoke-WebRequest -Uri $Url).Links |
    Where-Object {
      $_.href -Match "v[0-9]+\.[0-9]+\.[0-9]+"
    })[-1].href -Replace "[v/]", ""
}

Function Build-Configuration-Information {
  $downloads_url_prefix = "https://downloads.datastax.com/cpp-driver/windows"
  $dependencies_url_prefix = "$($downloads_url_prefix)/dependencies"

  # Gather dependency versions
  $libuv_version = Get-Latest-Version -Url "$($dependencies_url_prefix)/libuv"
  $openssl_version = Get-Latest-Version -Url "$($dependencies_url_prefix)/openssl"
  $driver_version = Get-Latest-Version -Url "$($downloads_url_prefix)/dse"

  # Determine the architecture platform and generate the suffix for the archive
  $architecture = "32"
  If ($Env:Platform -Like "x64") {
    $architecture = "64"
  }
  $dependency_arhive_suffix = "win$($architecture)-msvc$($Env:VISUAL_STUDIO_INTERNAL_VERSION).zip"

  # Gather URLs for example dependencies
  $Env:LIBUV_URL = "$($dependencies_url_prefix)/libuv/v$($libuv_version)/libuv-$($libuv_version)-$($dependency_arhive_suffix)"
  $Env:OPENSSL_URL = "$($dependencies_url_prefix)/openssl/v$($openssl_version)/openssl-$($openssl_version)-$($dependency_arhive_suffix)"
  $Env:DRIVER_URL = "$($downloads_url_prefix)/dse/v$($driver_version)/dse-cpp-driver-$($driver_version)-$($dependency_arhive_suffix)"

  $output = @"
Visual Studio: $($Env:CMAKE_GENERATOR.Split(" ")[-2]) [$($Env:CMAKE_GENERATOR.Split(" ")[-1])]
Architecture:  $($Env:Platform)
libuv:         v$($libuv_version)
OpenSSL:       v$($openssl_version)
DSE Driver:    v$($driver_version)
Build Number:  $($Env:APPVEYOR_BUILD_NUMBER)
Branch:        $($Env:APPVEYOR_REPO_BRANCH)
SHA:           $(Get-Commit-Sha)
"@
  Write-Host "$($output)" -BackgroundColor DarkGreen
}

Function Hardware-Information {
  $computer_system = Get-CimInstance CIM_ComputerSystem
  $operating_system = Get-CimInstance CIM_OperatingSystem
  $processor = Get-CimInstance CIM_Processor
  $logical_disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'"
  $capacity = "{0:N2}" -f ($logical_disk.Size / 1GB)
  $free_space = "{0:N2}" -f ($logical_disk.FreeSpace / 1GB)
  $free_space_percentage = "{0:P2}" -f ($logical_disk.FreeSpace / $logical_disk.Size)
  $ram = "{0:N2}" -f ($computer_system.TotalPhysicalMemory / 1GB)

  # Determine if hyper-threading is enabled in order to display number of cores
  $number_of_cores = "$($processor.NumberOfCores)"
  If ($processor.NumberOfCores -lt $processor.NumberOfLogicalProcessors) {
    $number_of_cores = "$($processor.NumberOfLogicalProcessors) (Hyper-Threading)"
  }

  $hardware_information = @"
Hardware Information for $($computer_system.Name):
  Operating System: $($operating_system.caption) (Version: $($operating_system.Version))
  CPU: $($processor.Name)
  Number of Cores: $($number_of_cores)
  HDD Capacity: $($capacity) GB
  HDD Free Capacity: $($free_space_percentage) ($($free_space) GB)
  RAM: $($ram) GB
"@
  Write-Host "$($hardware_information)" -BackgroundColor DarkMagenta
}

Function Environment-Information {
  Write-Host "Visual Studio Environment Variables:" -BackgroundColor DarkMagenta
  Get-ChildItem Env:VS* | ForEach-Object {
    Write-Host "  $($_.Name) = $($_.Value)" -BackgroundColor DarkMagenta
  }
}

Function Install-Libuv {
  Write-Host "Downloading and Extracting libuv"
  If ($Env:APPVEYOR -Like "True") {
    Start-FileDownload "$($Env:LIBUV_URL)" -FileName "libuv.zip"
  } Else {
    Write-Host "$($Env:LIBUV_URL)"
    curl.exe -o "libuv.zip" "$($Env:LIBUV_URL)"
  }

  7z x libuv.zip -o"$($Env:APPVEYOR_BUILD_FOLDER)/lib/libuv"
  Remove-Item libuv.zip
}

Function Install-Openssl {
  Write-Host "Downloading and Extracting OpenSSL"
  If ($Env:APPVEYOR -Like "True") {
    Start-FileDownload "$($Env:OPENSSL_URL)" -FileName "openssl.zip"
  } Else {
    curl.exe -o "openssl.zip" "$($Env:OPENSSL_URL)"
  }

  7z x openssl.zip -o"$($Env:APPVEYOR_BUILD_FOLDER)/lib/openssl"
  Move-Item -Path "$($Env:APPVEYOR_BUILD_FOLDER)/lib/openssl/shared/*" -Destination "$($Env:APPVEYOR_BUILD_FOLDER)/lib/openssl"
  Remove-Item openssl.zip
}

Function Install-Driver {
  Write-Host "Downloading and Extracting DataStax C/C++ DSE Driver"
  If ($Env:APPVEYOR -Like "True") {
    Start-FileDownload "$($Env:DRIVER_URL)" -FileName "dse.zip"
  } Else {
    curl.exe -o "dse.zip" "$($Env:DRIVER_URL)"
  }

  7z x dse.zip -o"$($Env:APPVEYOR_BUILD_FOLDER)/lib/dse"
  Remove-Item dse.zip
}

Function Install-Examples-Environment {
   Install-Libuv
   Install-Openssl
   Install-Driver
}

Function Build-Examples {
  # Determine the CMake generator to utilize
  $cmake_generator = $Env:CMAKE_GENERATOR
  If ($Env:Platform -Like "x64") {
    $cmake_generator += " Win64"
  }

  # Build the examples
  New-Item -ItemType Directory -Force -Path "$($Env:APPVEYOR_BUILD_FOLDER)/build"
  Push-Location "$($Env:APPVEYOR_BUILD_FOLDER)/build"
  Write-Host "Configuring DataStax C/C++ DSE driver Examples"
  cmake -G "$($cmake_generator)" ..
  If ($LastExitCode -ne 0) {
    Pop-Location
    Throw "Failed to configure DataStax C/C++ DSE Driver Examples for MSVC $($Env:VISUAL_STUDIO_INTERNAL_VERSION)-$($Env:Platform)"
  }
  Write-Host "Building and Installing DataStax C/C++ $($driver_type) Driver"
  cmake --build . --config RelWithDebInfo
  If ($LastExitCode -ne 0) {
    Pop-Location
    Throw "Failed to build DataStax C/C++ DSE Driver Examples for MSVC $($Env:VISUAL_STUDIO_INTERNAL_VERSION)-$($Env:Platform)"
  }
  Pop-Location
}
