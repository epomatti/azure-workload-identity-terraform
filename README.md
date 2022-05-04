# Azure Workload Identity with Terraform

https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#register-the-enableoidcissuerpreview-feature-flag


```bash
az login
```

First you need to enable OIDC Issuer as described in [this section](https://docs.microsoft.com/en-us/azure/aks/cluster-configuration#register-the-enableoidcissuerpreview-feature-flag) of the documentation:

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
terraform -chdir='azure' apply -auto-approve

terraform plan
terraform apply
```

https://azure.github.io/azure-workload-identity/docs/installation/mutating-admission-webhook.html