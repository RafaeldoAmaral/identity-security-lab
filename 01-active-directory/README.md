# Lab 01 — Active Directory: Identity Provisioning \& Security Monitoring


## 1. Objetivo

Este laboratório demonstra a criação e o provisionamento inicial de uma identidade no Microsoft Active Directory utilizando PowerShell, relacionando o processo de IAM (Identity and Access Management) com eventos de segurança utilizados em atividades de Blue Team.
O cenário implementa parte do processo de Joiner, no qual um novo colaborador recebe uma identidade, uma conta no Active Directory e posteriormente os acessos necessários para exercer sua função.
Além do provisionamento, foram analisados os eventos de segurança gerados pelo Domain Controller, permitindo relacionar operações de IAM com monitoramento e investigação de segurança.

## 2. Tecnologias utilizadas

* Microsoft Windows Server 2022
* Active Directory Domain Services (AD DS)
* Windows PowerShell
* Windows Security Event Log
* Event Viewer
* IAM / Identity Governance concepts

## 3. Ambiente do laboratório

O laboratório utiliza o domínio:

```text

lab.local

```

Estrutura principal utilizada:

```text

lab.local

│

├── OU=Usuarios

│   ├── OU=Colaboradores

│   ├── OU=Terceiros

│   ├── OU=Estagiarios

│   └── OU=Desligados

│

├── OU=Grupos

│   ├── OU=Seguranca

│   └── OU=Distribuicao

│

├── OU=Service Accounts

│

├── OU=Computadores

│

└── OU=Servidores

```
Essa estrutura permite separar identidades, grupos, contas de serviço, computadores e servidores, facilitando administração, delegação e aplicação de políticas.

# 4. Cenário de negócio

Foi simulada a contratação de uma nova colaboradora:



| Atributo       | Valor                                             |

| -------------- | ------------------------------------------------- |

| Nome           | Ana Souza                                         |

| Employee ID    | EMP002                                            |

| Departamento   | Financeiro                                        |

| Cargo          | Analista Financeiro                               |

| SamAccountName | ana.souza                                         |

| UPN            | ana.souza@lab.local                               |


O fluxo representado pelo laboratório é:

```text

Nova contratação

&#x20;      │

&#x20;      ▼

Identity

&#x20;      │

&#x20;      ▼

Active Directory Account

&#x20;      │

&#x20;      ▼

Department = Financeiro

&#x20;      │

&#x20;      ▼

GRP\_FIN\_Leitura

&#x20;      │

&#x20;      ▼

Acesso aos recursos financeiros

```

# 5. Validação antes do provisionamento

Antes da criação da conta, foi realizada uma verificação para evitar duplicidade de identidade.

Validação do Employee ID:

```powershell

Get-ADUser -Filter "EmployeeID -eq 'EMP002'" -Properties EmployeeID |

Select-Object Name,SamAccountName,EmployeeID

```

Validação do SamAccountName:

```powershell

Get-ADUser -Filter "SamAccountName -eq 'ana.souza'"

```

Essa etapa representa um controle importante em processos de IAM, pois evita a criação de identidades ou contas duplicadas.

# 6. Criação da identidade no Active Directory

A senha inicial foi solicitada de forma segura utilizando:

```powershell

$Password = Read-Host "Digite a senha inicial" -AsSecureString

```
Em seguida, a conta foi criada:

```powershell

New-ADUser `

\-Name "Ana Souza" `

\-GivenName "Ana" `

\-Surname "Souza" `

\-SamAccountName "ana.souza" `

\-UserPrincipalName "ana.souza@lab.local" `

\-EmployeeID "EMP002" `

\-Department "Financeiro" `

\-Title "Analista Financeiro" `

\-EmailAddress "ana.souza@lab.local" `

\-Path "OU=Colaboradores,OU=Usuarios,DC=lab,DC=local" `

\-AccountPassword $Password `

\-Enabled $true `

\-ChangePasswordAtLogon $true

```
A opção:

```powershell

\-ChangePasswordAtLogon $true

```
obriga o usuário a definir uma nova senha durante o primeiro logon.

# 7. Validação da conta

Após o provisionamento, os principais atributos foram consultados:

```powershell

Get-ADUser ana.souza -Properties mail,department,title,employeeID |

Select-Object Name,

&#x20;             SamAccountName,

&#x20;             UserPrincipalName,

&#x20;             DistinguishedName,

&#x20;             SID,

&#x20;             Enabled,

&#x20;             mail,

&#x20;             department,

&#x20;             title,

&#x20;             employeeID

```

Essa validação confirma se os atributos recebidos durante o processo de provisionamento foram corretamente gravados no Active Directory.

# 8. Atributos importantes para IAM

Durante o laboratório foram analisados alguns dos principais atributos utilizados na gestão de identidades.

### SamAccountName

Representa o nome de logon tradicional da conta no Active Directory.
Exemplo:

```text

LAB\\ana.souza

```
### UserPrincipalName

Identificador de logon no formato:

```text

ana.souza@lab.local

```
### DistinguishedName

Representa a localização do objeto dentro da estrutura LDAP.
Exemplo:

```text

CN=Ana Souza,OU=Colaboradores,OU=Usuarios,DC=lab,DC=local

```
### SID

O Security Identifier é utilizado pelo Windows para identificar o security principal em operações de autorização e controle de acesso.

### EmployeeID

O EmployeeID pode funcionar como atributo de correlação entre uma fonte autoritativa de RH, uma solução IGA e sistemas de destino.

Exemplo:

```text

HR Database

EmployeeID = EMP002

&#x20;      │

&#x20;      ▼

IGA

Personnel Number = EMP002

&#x20;      │

&#x20;      ▼

Active Directory

EmployeeID = EMP002

```

# 9. PasswordLastSet

Durante a validação foi observado:

```text

pwdLastSet = 0

```
Esse estado é compatível com a configuração utilizada para exigir alteração de senha no próximo logon.

Fluxo esperado:

```text

IAM cria identidade

&#x20;      ↓

Senha inicial definida

&#x20;      ↓

pwdLastSet = 0

&#x20;      ↓

Primeiro logon

&#x20;      ↓

Usuário altera a senha

&#x20;      ↓

PasswordLastSet atualizado

```

# 10. Monitoramento — Event ID 4720

A criação da conta gerou um evento no Windows Security Log:

```text

Event ID: 4720

A user account was created

```
O evento permitiu identificar:

```text

Subject

&#x20;  │

&#x20;  │ realizou a criação

&#x20;  ▼

New Account

```
No cenário do laboratório:

```text

LAB\\Administrator

&#x20;      │

&#x20;      │ criou

&#x20;      ▼

LAB\\ana.souza

```
O campo Subject identifica a identidade responsável pela operação.
O campo New Account identifica a nova conta criada.
Também foi identificado um Logon ID, que pode ser utilizado para correlacionar a operação com outros eventos relacionados à mesma sessão.

# 11. Correlação de eventos

Em uma investigação de segurança, o Event ID 4720 não deve necessariamente ser analisado isoladamente.
Uma possível correlação seria:

```text

4624

Successful Logon

&#x20;      │

&#x20;      │ Logon ID

&#x20;      ▼

4720

User Account Created

```
Isso permite reconstruir parte da timeline e identificar a sessão que originou determinada alteração no Active Directory.

# 12. Provisionamento de acesso



Como a colaboradora pertence ao departamento Financeiro, foi definido para o laboratório que o grupo:

```text

GRP\_FIN\_Leitura

```
representa um acesso básico necessário aos colaboradores desse departamento.

Regra simulada:

```text

Department = Financeiro

&#x20;       +

Account = Enabled

&#x20;       ↓

GRP\_FIN\_Leitura

```
Esse cenário representa um exemplo simplificado de Birthright Access.

A inclusão foi realizada utilizando:

```powershell

Add-ADGroupMember `

\-Identity "GRP\_FIN\_Leitura" `

\-Members "ana.souza"

```
# 13. Monitoramento — Event ID 4728

Após a inclusão da identidade no grupo de segurança, foi identificado:

```text

Event ID: 4728

A member was added to a security-enabled global group

```
O evento permite identificar três elementos importantes:

```text

Subject

&#x20;  │

&#x20;  │ adicionou

&#x20;  ▼

Member

&#x20;  │

&#x20;  │ ao

&#x20;  ▼

Group

```
No cenário:

```text

Administrator

&#x20;      │

&#x20;      ▼

Ana Souza

&#x20;      │

&#x20;      ▼

GRP\_FIN\_Leitura

```
Esse tipo de evento é importante para monitoramento de alterações de acesso no Active Directory.


# 14. Perspectiva de Blue Team

A inclusão de um usuário em um grupo não representa necessariamente atividade maliciosa.
O contexto precisa ser analisado.
Por exemplo:

```text

Ana Souza

Department = Financeiro

&#x20;      ↓

GRP\_FIN\_Leitura

&#x20;      ↓

Acesso compatível com a função

```
Por outro lado:


```text

Usuário comum

&#x20;     ↓

Domain Admins

&#x20;     ↓

Alteração inesperada

&#x20;     ↓

INVESTIGAR

```
Durante uma investigação, alguns pontos importantes são:



1\. Quem realizou a alteração?

2\. Qual usuário recebeu o acesso?

3\. Qual grupo foi atribuído?

4\. O acesso é compatível com a função do usuário?

5\. Existe solicitação ou aprovação correspondente?

6\. A conta que realizou a alteração possui autorização para isso?

7\. Existem outros eventos suspeitos relacionados à mesma sessão?


# 15. Relação entre IAM e Blue Team

O laboratório demonstra como uma mesma operação pode ser analisada sob perspectivas diferentes.



```text

&#x20;            IDENTITY

&#x20;                │

&#x20;       ┌────────┴────────┐

&#x20;       │                 │

&#x20;      IAM            BLUE TEAM

&#x20;       │                 │

Provisionamento       Detecção

&#x20;       │                 │

AD Account            Event 4720

&#x20;       │                 │

Entitlement           Event 4728

&#x20;       │                 │

Access Policy         Investigação

&#x20;       └────────┬────────┘

&#x20;                │

&#x20;         Identity Security

```

IAM busca responder:

> O usuário deveria possuir esse acesso?

Blue Team busca responder:

> A alteração foi legítima e realizada da maneira esperada?


A combinação dessas duas perspectivas permite aplicar conceitos de Identity Security.

# 16. Controles de segurança envolvidos

Os principais conceitos aplicados neste laboratório foram:



* Identity Provisioning
* Joiner
* Birthright Access
* RBAC
* Least Privilege
* Entitlements
* Identity Correlation
* Active Directory Security Groups
* Security Event Monitoring
* Event Correlation
* Identity Threat Detection

# 17. Eventos analisados



| Event ID | Descrição                                     | Utilização                                      |

| -------- | --------------------------------------------- | ----------------------------------------------- |

| 4720     | User account created                          | Detectar criação de contas                      |

| 4728     | Member added to security-enabled global group | Monitorar concessões de acesso                  |

| 4624     | Successful logon                              | Possível correlação com sessões de autenticação |

# 18. Principais aprendizados

Este laboratório permitiu praticar o ciclo inicial de uma identidade no Active Directory, desde a criação da conta até a concessão de acesso.
Também demonstrou que operações administrativas deixam evidências nos logs de segurança do Windows, permitindo que processos de IAM sejam correlacionados com atividades de monitoramento e investigação de Blue Team.
O principal aprendizado é que segurança de identidade não consiste apenas em criar contas e atribuir grupos.
É necessário responder continuamente:

```text

Quem possui acesso?

&#x20;       ↓

A qual recurso?

&#x20;       ↓

Por qual motivo?

&#x20;       ↓

Quem concedeu?

&#x20;       ↓

A concessão foi autorizada?

&#x20;       ↓

O acesso ainda é necessário?

```

Essas perguntas conectam IAM, Identity Governance e Blue Team.

## Próximos passos

O próximo laboratório expandirá esse cenário para o ciclo de vida da identidade, abordando:

* Access Review
* Revogação de acesso
* Mover
* Alteração de departamento
* Deprovisioning
* Eventos de segurança relacionados
* Least Privilege
* Joiner / Mover / Leaver



