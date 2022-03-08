variable "cidr_blocks" {
    type = list(string)
    description = "List of cidr ranges to be used for pvc/subnet, minimum 2 required"
    validation { 
        condition= length(var.cidr_blocks) > 1
        error_message = "Cidr_block needs to have at least 2 cidrranges."
    }
}

variable "image_id" {
    type = string
    description = "Needs to be a valid AMI id"
    validation {
        condition = can(regex("^ami-", var.image_id))
        error_message = "Image_id must be a valid AMI id."
    }
}

variable "instance_name" {
    type = string
    default = "terraform_instance"
}

output "blocks" {
    value = var.cidr_blocks
}
output "image_id" {
    value = var.image_id
}



