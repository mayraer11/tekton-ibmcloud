provider "ibm" {
  generation       = "2"
  region           = "us-south"
  ibmcloud_api_key = var.ibmcloud_api_key
}

data "ibm_space" "spacedata" {
  org   = "DEMO"
  name  = var.environment
}

data "ibm_app_domain_shared" "domain" {
  name = "mybluemix.net"
}

data "archive_file" "app" {
  type        = "zip"
  source_dir = "${path.module}/src"
  output_path = "${path.module}/app.zip"
}

resource "ibm_app_route" "approute-demo-001" {
  domain_guid = data.ibm_app_domain_shared.domain.id
  space_guid  = data.ibm_space.spacedata.id
  host        = "cf-demo-${var.environment}-001"
}

resource "ibm_app" "cf-demo-001" {
  name                 = "cf-demo-${var.environment}-001"
  space_guid           = data.ibm_space.spacedata.id
  app_path             = "app.zip"
  buildpack            = "sdk-for-nodejs"
  route_guid           = ["${ibm_app_route.approute-demo-001.id}"]
  app_version          = "1"
  instances            = 2
  tags                 = ["${var.environment}"]
}