
## Documentation & Help

### Documenation SFDX, Scratch Orgs, and Development Best Practices
- [Salesforce Scratch Orgs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs.htm)
- [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) 
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
- [Development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models)
- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)

### Install Tools

1. [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm)
2. [Install GIT](https://github.com/git-guides/install-git)
3. [Github Signup](https://github.com)
4. Open Terminal or Command Prompt
5. sfdx update
6. git help

### Deploying GRAX

Please follow [deployment instructions](./README.md) after your developer tools configured.

### Deploying to Scratch Orgs

Please refer to how to utilize [Salesforce Scratch Orgs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs.htm)
```
sfdx force:source:push -u GRAXDev
```

### Deploying to Non Scratch Orgs
To deploy GRAX to NON scratch orgs below are sample deployments. This will add the GRAX-Salesforce-Embedded into your Sandbox. You would then use your standard testing, deployment, patching, and release management to push GRAX-Salesforce-Embedded out.
```
sfdx force:source:deploy -p force-app/main/default -u grax-testdrive
sfdx force:source:deploy -p force-app/main/default -u grax-completedemo
```

### Sample Tests
```
```

sfdx force:apex:test:run -c -u GRAXDev -r human

```                      
```

