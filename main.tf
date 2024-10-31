terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}

variable "ssh_key" {
  description = "Huella digital de la clave SSH"
  default     = "ee:49:51:1d:6e:84:94:56:2b:b7:c8:de:2b:1c:42:2e"
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "web" {
  image  = "ubuntu-20-04-x64"
  name   = "discard"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [var.ssh_key]

    provisioner "remote-exec" {
      inline = [
        "sudo apt update",
        "sudo apt install -y docker.io",
        "sudo systemctl start docker",
        "sudo systemctl enable docker",
        "sudo usermod -aG docker $USER"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ipv4_address
      private_key = file("/var/jenkins_home/.ssh/id_ed25519") 
      agent       = false  
    }
    
  }
}

resource "digitalocean_droplet_firewall" "web_firewall" {
  droplet_ids = [digitalocean_droplet.web.id]
  firewall_id = "Firewall"
  id = data.digitalocean_firewall.existing.id
}