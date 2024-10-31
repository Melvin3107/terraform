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
  ssh_keys = "ee:49:51:1d:6e:84:94:56:2b:b7:c8:de:2b:1c:42:2e"

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
      private_key = file("~/.ssh/id_ed25519")
    }
  }
}

resource "digitalocean_firewall" "web" {
  name = "only-22-80-and-443"
  droplet_ids = [digitalocean_droplet.web.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
