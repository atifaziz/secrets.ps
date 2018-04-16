# secrets.ps

This project contains stand-alone PowerShell scripts to save a secret, such as
a password, to a file and test the secret later.

The secret is protected using Windows [DPAPI][dpapi] (Data Protection API) and
saved to a plain text file using [Base64][base64] encoding.

To save a secret to a file, use `Set-Secret.ps1` as follows:

    .\Set-Secret.ps1 -FilePath password

The script will prompt for the secret to be saved and save it encrypted to a
file called `password`. The encryption uses the user's key by default.
Supplying the `-ForHost` will encrypt using the machine key:

    .\Set-Secret.ps1 -FilePath password -ForHost

To test a secret previously saved to a file, use `Test-Secret.ps1`:

    .\Test-Secret.ps1 -FilePath password

The script will prompt for the secret to test then checks if it is the same
as the secret saved in the file. It returns `True` if the match is successful
otherwise it emits an error.

`Test-Secret.ps1` can find out if the secret was encrypted using the user's
or machine's key. The information is stored in an [alternate data stream][ads]
named `DataProtectionScope` that either contains a line reading `CurrentUser`
or `LocalMachine`. If this is lost then `Test-Secret.ps1` assumes
`CurrentUser`. To force `LocalMachine`, supply the `-ForHost` switch.


[dpapi]: https://msdn.microsoft.com/en-us/library/ms995355.aspx
[base64]: https://en.wikipedia.org/wiki/Base64
[ads]: https://blogs.technet.microsoft.com/askcore/2013/03/24/alternate-data-streams-in-ntfs/
