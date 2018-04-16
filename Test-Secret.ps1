<#
 # MIT License
 #
 # Copyright (c) 2018 Atif Aziz
 #
 # Permission is hereby granted, free of charge, to any person obtaining a copy
 # of this software and associated documentation files (the "Software"), to deal
 # in the Software without restriction, including without limitation the rights
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 # copies of the Software, and to permit persons to whom the Software is
 # furnished to do so, subject to the following conditions:
 #
 # The above copyright notice and this permission notice shall be included in all
 # copies or substantial portions of the Software.
 #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 # SOFTWARE.
 #>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [securestring]$Secret,
    [switch]$ForHost = $false)

$ErrorActionPreference = 'stop'

Add-Type -AssemblyName System.Security

[string]$scope =
    type $FilePath -Stream DataProtectionScope -ErrorAction SilentlyContinue |
        % { $_.Trim() } |
        select -First 1

if (-not $scope)
{
    $scope = if ($forHost) { 'LocalMachine' } else { 'CurrentUser' }
}

Write-Verbose "Unprotecting secret from file using the scope `"$scope`"."

$utf8 = New-Object Text.Utf8Encoding # without BOM!
$protectedSecret = [Convert]::FromBase64String((type $filePath -Raw))
$testSecret = $utf8.GetString([Security.Cryptography.ProtectedData]::Unprotect($protectedSecret, $null, $scope))

[IntPtr]$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
[string]$secretText = $null
try
{
    $secretText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
}
finally
{
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

$ok = $testSecret -ne $secretText

# evict secret from managed memory immediately

$secretText = $null
$protectedSecret = $null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

if (-not $ok)
{
    Write-Error 'Invalid secret.'
    $false
}

$ok
