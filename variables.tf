
variable "aws_region" {
    description = "The AWS region things are created in"
    default = "us-east-1"
}

variable "ec2_task_execution_role_name" {
    description = "ECS task execution role name"
    default = "myEcsTaskExecutionRole"
}

variable "ecs_auto_scale_role_name" {
    description = "ECS auto scale role name"
    default = "myEcsAutoScaleRole"
}

variable "az_count" {
    description = "Number of AZs to cover in a given region"
    default = "2"
}

variable "app_image" {
    description = "Docker image to run in the ECS cluster"
    default = "bradfordhamilton/crystal_blockchain:latest"
}

variable "app_port" {
    description = "Port exposed by the docker image to redirect traffic to"
    default = 3000

}

variable "app_count" {
    description = "Number of docker containers to run"
    default = 3
}

variable "health_check_path" {
  default = "/"
}

variable "fargate_cpu" {
    description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
    default = "1024"
}

variable "fargate_memory" {
    description = "Fargate instance memory to provision (in MiB)"
    default = "2048"
}


variable "project" {
  # Change this with your Project name
  default     =  "umbraco"
  type        = string
}

variable "region" {
  default     =  "ap-south-1"
  type        = string
}

data "aws_availability_zones" "example" {
   state = "available"
}
output "availability_zones" {
  value = data.aws_availability_zones.example.names
}
variable "availability_zones" {
  default     =[
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c",
]
  type        = list  
  description = "List of availability zones"
}
variable "vpc_cidr" {
  # CIDR for your new VPC , 10.0.0.0/16 means you can not change first 10.0 (16 bits) when creating subnetwork(subnet, private or piblci)
  default     = "10.0.0.0/16"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  # Change this if change vpc_cidr

  default     = ["10.0.0.0/24", "10.0.2.0/24",  "10.0.3.0/24",]
  type        = list
  description = "List of public subnet CIDR blocks"
}
variable "private_subnet_cidr_blocks" {

  # Change this if change vpc_cidr
  default     = ["10.0.100.0/24", "10.0.101.0/24" , "10.0.102.0/24" ]
  type        = list
  description = "List of private subnet CIDR blocks"
}



 