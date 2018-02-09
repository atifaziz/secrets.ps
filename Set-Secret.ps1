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
    [switch]$ForHost = $false,
    [switch]$DontSaveScope = $false)

$ErrorActionPreference = 'stop'

Add-Type -AssemblyName System.Security

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

$scope = if ($forHost) { 'LocalMachine' } else { 'CurrentUser' }

$utf8 = New-Object Text.Utf8Encoding # without BOM!
$protectedSecret = [Security.Cryptography.ProtectedData]::Protect($utf8.GetBytes($secretText), $null, $scope)

[Convert]::ToBase64String($protectedSecret) | Out-File $filePath -Encoding ascii

if (-not $dontSaveScope)
{
    $scope | sc $FilePath -Stream DataProtectionScope
}

Write-Verbose "Secret saved to `"$filePath`" for the scope of `"$scope`"."

# evict secret from managed memory immediately

$secretText = $null
$protectedSecret = $null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
