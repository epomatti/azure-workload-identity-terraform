# Azure Workload Identity w/ Terraform

Terraform modules to setup an AKS Cluster integrated with Workload Identity, allowing your pods to connect to Azure resources using Managed Identity.

This repository is a Terraform-flavored version of the AWI [Quick Start](https://azure.github.io/azure-workload-identity/docs/quick-start.html) documentation.

## Architecture



## Deployment

### 1 - Enable OIDC Issuer Preview

Head over to this Microsoft Docs section: **[Register the `EnableOIDCIssuerPreview` feature flag](https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#register-the-enableoidcissuerpreview-feature-flag)**

Enable the feature (`az feature register`) and propagate it (`az provider register`).

Then return here and continue. You don't need to install or create anything else as everything will be configured and managed by the Terraform modules.


### 2 - Create the Azure resources

Creates the AKS Cluster, Key Vault, and App Registration/

```bash
terraform -chdir='azure' init
terraform -chdir='azure' apply -var-file='../variables.tfvars' -auto-approve
```

### 3 - Configure Kubernetes

```sh
terraform -chdir='helm' init
terraform -chdir='helm' apply -var-file='../variables.tfvars' -auto-approve

terraform -chdir='kubernetes' init
terraform -chdir='kubernetes' apply -var-file='../variables.tfvars' -auto-approve
```

That's it! You should now be able to get the 

```bash
$ az aks get-credentials -g '<resource_group_name>' -n '<ask_cluster_name>'

$ kubectl logs quick-start
successfully got secret, secret=Hello!
```

---

### Clean Up

Delete the resources to unwanted avoid costs:

```sh
terraform -chdir='azure' destroy -var-file='../variables.tfvars' -auto-approve
```
