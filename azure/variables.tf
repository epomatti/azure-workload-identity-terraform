variable "app_name" {
  type        = string
  description = "The root name of the application, as an alphanumeric short value."
}

variable "location" {
  type        = string
  description = "The Azure location on which to create the resources."
  default     = "westus"
}

variable "aks_vm_size" {
  description = "Kubernetes VM size."
  type        = string
  default     = "Standard_B2s"
}
