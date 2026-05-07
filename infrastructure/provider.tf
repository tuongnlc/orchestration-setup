terraform {
  required_providers {
    kafka = {
      source  = "Mongey/kafka"
      version = "~> 0.7.0"
    }
  }
}

provider "kafka" {
  bootstrap_servers = ["127.0.0.1:9094"]
  timeout           = 120
#   skip_tls_verify   = true 
    tls_enabled    = false
}
