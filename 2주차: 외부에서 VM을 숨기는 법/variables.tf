
variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "The GCP zone."
  type        = string
  default     = "asia-northeast3-a"
}

variable "vpc_network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "gemini-vpc"
}

variable "public_subnet_name" {
  description = "The name of the public subnet."
  type        = string
  default     = "public-subnet"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
}

variable "private_subnet_name" {
  description = "The name of the private subnet."
  type        = string
  default     = "private-subnet"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet."
  type        = string
}

variable "public_vm_name" {
  description = "The name of the public VM."
  type        = string
  default     = "public-vm"
}

variable "private_vm_name" {
  description = "The name of the private VM."
  type        = string
  default     = "private-vm"
}

variable "machine_type" {
  description = "The machine type for the VMs."
  type        = string
  default     = "f1-micro"
}

variable "image" {
  description = "The boot disk image for the VMs."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "router_name" {
  description = "The name of the Cloud Router."
  type        = string
  default     = "nat-router"
}

variable "nat_gateway_name" {
  description = "The name of the NAT gateway."
  type        = string
  default     = "nat-gateway"
}
