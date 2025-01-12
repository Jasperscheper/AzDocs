[[_TOC_]]

# Description

There are two ways to enable application monitoring for Azure Function Apps hosted applications:

- Agent-based application monitoring (ApplicationInsightsAgent).

This method is the easiest to enable, and no advanced configuration is required. It is often referred to as "runtime" monitoring (codeless deployment).

- Manually instrumenting the application through code by installing the Application Insights SDK.

This approach is much more customizable, but it requires adding a dependency on the Application Insights SDK NuGet packages.

**This snippet will add Agent-based application monitoring (ApplicationInsightsAgent) on your function app. This is the codeless deployment.**

# Parameters

Some parameters from [General Parameter](/Azure/AzDocs-v1/Scripts) list.

| Parameter                    | Required                        | Example Value                                                | Description                                                                                                                                         |
| ---------------------------- | ------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| AppInsightsName              | <input type="checkbox" checked> | `MyTeam-AzureTestApi-$(Release.EnvironmentName)-AppInsights` | The name of the AppInsights resource to use.                                                                                                        |
| FunctionAppName              | <input type="checkbox" checked> | `MyTeam-AzureTestApi-$(Release.EnvironmentName)`             | The name of the WebApp resource the AppInsights settings will be configured on.                                                                     |
| FunctionAppResourceGroupName | <input type="checkbox" checked> | `MyTeam-AzureTestApi-$(Release.EnvironmentName)`             | The name of the Resource Group where the AppService resource resides. Typically this is the same ResourceGroup as the appInsightsResourceGroupName  |
| AppInsightsResourceGroupName | <input type="checkbox" checked> | `MyTeam-AzureTestApi-$(Release.EnvironmentName)`             | The name of the Resource Group where the AppInsights resource resides. Typically this is the same ResourceGroup as the appInsightsResourceGroupName |
| EnableExtensiveDiagnostics   | <input type="checkbox">         | `$true`/`$false`                                             | Enable extensive diagnostics. This might affect performance of your application stack. Please use with caution. Defaults to `$false`.               |
| AppServiceSlotName           | <input type="checkbox">         | `staging`                                                    | Select a specific slot to run this script on                                                                                                        |
| ApplyToAllSlots              | <input type="checkbox">         | `$true`/`$false`                                             | Applies the current script to all slots revolving the functionapp                                                                                   |

# YAML

Be aware that this YAML example contains all parameters that can be used with this script. You'll need to pick and choose the parameters that are needed for your desired action.

```yaml
- task: AzureCLI@2
  displayName: "Create Application Insights Extension for FunctionApps codeless"
  condition: and(succeeded(), eq(variables['DeployInfra'], 'true'))
  inputs:
    azureSubscription: "${{ parameters.SubscriptionName }}"
    scriptType: pscore
    scriptPath: "$(Pipeline.Workspace)/AzDocs/AppInsights/Create-Application-Insights-Extension-for-FunctionApps-codeless.ps1"
    arguments: "-AppInsightsName '$(AppInsightsName)' -AppInsightsResourceGroupName '$(AppInsightsResourceGroupName)' -FunctionAppName '$(FunctionAppName)' -FunctionAppResourceGroupName '$(FunctionAppResourceGroupName)' -EnableExtensiveDiagnostics $(EnableExtensiveDiagnostics) -AppServiceSlotName '$(AppServiceSlotName)' -ApplyToAllSlots $(ApplyToAllSlots)"
```

# Code

[Click here to download this script](../../../../src/AppInsights/Create-Application-Insights-Extension-for-FunctionApps-codeless.ps1)

# Links

- [Monitor Azure App Service performance](https://docs.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps?tabs=net)

- [Azure CLI - Automating Application Insights extension](https://markheath.net/post/automate-app-insights-extension)
