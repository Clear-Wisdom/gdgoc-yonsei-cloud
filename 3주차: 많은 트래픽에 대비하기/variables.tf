variable "project_id" {
  type        = string
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

variable "zones" {
  type        = list(string)
  default     = [
    "asia-northeast3-a",
    "asia-northeast3-b",
  ]
}
