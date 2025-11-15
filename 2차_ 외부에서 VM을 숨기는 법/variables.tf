
variable "project_id" {
  type        = string
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  type        = string
  default     = "asia-northeast3-a"
}

variable "vpc_network_name" {
  type        = string
  default     = "gemini-vpc"
}

variable "public_subnet_name" {
  type        = string
  default     = "public-subnet"
}

variable "public_subnet_cidr" {
  type        = string
}

variable "private_subnet_name" {
  type        = string
  default     = "private-subnet"
}

variable "private_subnet_cidr" {
  type        = string
}

variable "public_vm_name" {
  type        = string
  default     = "public-vm"
}

variable "private_vm_name" {
  type        = string
  default     = "private-vm"
}

variable "machine_type" {
  type        = string
  default     = "f1-micro"
}

variable "image" {
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "router_name" {
  type        = string
  default     = "nat-router"
}

variable "nat_gateway_name" {
  type        = string
  default     = "nat-gateway"
}

variable "vm_service_account_id" {
  description = "Service account ID (without domain) to attach to VMs and target in firewall."
  type        = string
  default     = "vm-service"
}
