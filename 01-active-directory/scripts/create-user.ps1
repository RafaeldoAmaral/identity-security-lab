Import-Module ActiveDirectory

$Password = Read-Host "Digite a senha inicial" -AsSecureString

New-ADUser `
-Name "Ana Souza" `
-GivenName "Ana" `
-Surname "Souza" `
-SamAccountName "ana.souza" `
-UserPrincipalName "ana.souza@lab.local" `
-EmployeeID "EMP002" `
-Department "Financeiro" `
-Title "Analista Financeiro" `
-EmailAddress "ana.souza@lab.local" `
-Path "OU=Colaboradores,OU=Usuarios,DC=lab,DC=local" `
-AccountPassword $Password `
-Enabled $true `
-ChangePasswordAtLogon $true