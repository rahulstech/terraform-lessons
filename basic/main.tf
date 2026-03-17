# set variable 
# method 1: terraform apply -var="name=Rahul"
#
# method 2: export TF_VAR_name=Rahul && terraform apply
#
# method 3: from file
# .auto.trvars / .auto.trvars.json => any name but must end with .auto.trvars or .auto.trvars.json
# terraform.trvars / terraform.trvars.json => exact same name 
# 
# custom .trvars / .trvars.json are loaded via
# -var-file="filename.trvars" or -var-file="filename.trvars.json"
#
# use variable for supply environment values
#
# 

variable "name" {
    type = string
    description = "the name variable"
    default = "unknown"
}

variable "age" {
    type = number
    description = "the age variable"
    default = 0
}

variable "gender" {
  type = string
  description = "the gender variable"
  validation {
    condition = contains(["Male","Female","Other"],var.gender)
    error_message = "gender must be one of Male, Female or Other"
  }
}

output "greeting" {
    value = "Name=${var.name}, Age=${var.age}, Gender=${var.gender}"
}