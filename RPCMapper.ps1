
$DbgHelpDllPath = "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll"
$OutputPath = "C:\Users\Administrator\rpcmethods"

# Importing NTObjectManager Module
Import-Module NtObjectManager -Scope Local

# *****************
# Collect Modules *
# *****************

$allModules = Get-ChildItem "$env:windir\system32\*" -Include "*.dll","*.exe"
#$allModules = Get-ChildItem "C:\tmp\*" -Include "*.dll","*.exe"

# *********************
# Extract RPC Servers *
# *********************

$allRpcFunctions = @()
$rpcUUIDMap = @{}

$modRpcServers = $allModules | Get-RpcServer -DbgHelpPath $dbghelpDllPath

foreach ($server in $modRpcServers) {
    if ($rpcUUIDMap[$server.InterfaceId.Guid] -ne $null){
        write-host "[*]" Interface: $server.InterfaceId.Guid "already inside. Process:" $server.FilePath
    }
    
    $rpcUUIDMap[$server.InterfaceId.Guid] = $server
    $procedures = [System.Collections.ArrayList]@()
    foreach ($procedure in $server.Procedures){
       $procedures.Add($procedure.Name)
     }

    $rpcFuncObject = [pscustomobject] @{
        Module   = $server.Name
        ModulePath = $server.FilePath
        InterfaceId = $server.InterfaceId
        InterfaceStructOffset = $server.Offset
        ProceduresCount = $server.ProcedureCount
        Procedures = $procedures
        ProcStackSize = $procedure.StackSize
        DispatchFunction = $procedure.DispatchFunction
        Service = $server.ServiceName
        IsServiceRunning = $server.IsServiceRunning
    }

    $rpcUUIDMap[$server.InterfaceId.Guid] = $rpcFuncObject
}

# ****************
# Export Results *
# ****************

$rpcUUIDMap | ConvertTo-Json -Compress -depth 100 | Out-File -append "$OutputPath\RPCUUIDMap_Server2019.json"
