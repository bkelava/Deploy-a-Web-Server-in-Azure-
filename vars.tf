variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "West Europe"
}

variable "username" {
    description = "Provide Azure username."
    default = "kelava"
}

variable "password" {
    description = "Provide Azure password."
    default = "DbJ3u3rW!!!!!!!!"
}

variable "packer_resource_group_name" {
   description = "Name of the resource group in which the Packer image will be created"
   default     = "packer-rg"
}

variable "packer_image_name" {
   description = "Name of the Packer image"
   default     = "myPackerImage"
}

variable "tag" {
  description ="Tag used in all sources."
  default = "project1"
}

variable "server_names" {
  description = "Enter your server names: "
  type = list(string)
  default = ["sr1", "sr2"]
  }

variable "count_of_vm" {
  description = "Count of virtual machines"

  validation {
    condition = (var.count_of_vm > 1) ? true : false
    error_message = "Count of VM must be greater than 1!"
  }

   default = "2"
}