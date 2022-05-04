# Azure Workload Identity with Terraform

##

## 

Start by logging into Azure:

```bash
az login
```

First you need to enable OIDC Issuer Preview, as described in [this section](https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#register-the-enableoidcissuerpreview-feature-flag) of the documentation:

```bash
# Enable the feature
az feature register --name 'EnableOIDCIssuerPreview' --namespace 'Microsoft.ContainerService'

# Wait for the status to change to "Registered" - This can take a while
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableOIDCIssuerPreview')].{Name:name,State:properties.state}"

# Once the feature has been "Registered", propagate with this command
az provider register --namespace 'Microsoft.ContainerService'
```



```bash
terraform -chdir='azure' init
terraform -chdir='azure' apply -var-file='../variables.tfvars' -auto-approve

terraform -chdir='helm' init
terraform -chdir='helm' apply -var-file='../variables.tfvars' -auto-approve

terraform -chdir='kubernetes' init
terraform -chdir='kubernetes' apply -var-file='../variables.tfvars' -auto-approve
```




group='<resource_group_name>'
aks='<ask_cluster_name>'

az aks get-credentials -g $group -n $aks

az aks get-credentials -g rg-azwiexmp-52139 -n aks-azwiexmp-52139





https://azure.github.io/azure-workload-identity/docs/installation/mutating-admission-webhook.html