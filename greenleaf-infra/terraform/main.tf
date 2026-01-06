data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
}

locals {
  common_tags = {
    Project = var.project_name
    Managed = "terraform"
  }
}
