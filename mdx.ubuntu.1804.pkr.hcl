variable "ubuntu_1804_version" {
  default = "18.04.5"
}

variable "preseed_path" {
  type    = string
  default = "ubuntu_preseed.cfg"
}

variable "guest_additions_url" {
  type    = string
  default = ""
}

variable "headless" {
  type    = bool
  default = false
}

locals {
  iso_url_ubuntu_1804          = "http://cdimage.ubuntu.com/ubuntu/releases/18.04/release/ubuntu-${var.ubuntu_1804_version}-server-amd64.iso"
  iso_checksum_url_ubuntu_1804 = "http://cdimage.ubuntu.com/ubuntu/releases/18.04/release/SHA256SUMS"
  ubuntu_1804_boot_command = [
    "<esc><wait>",
    "<esc><wait>",
    "<enter><wait>",
    "/install/vmlinuz<wait>",
    " auto<wait>",
    " console-setup/ask_detect=false<wait>",
    " console-setup/layoutcode=us<wait>",
    " console-setup/modelcode=pc105<wait>",
    " debconf/frontend=noninteractive<wait>",
    " debian-installer=en_US.UTF-8<wait>",
    " fb=false<wait>",
    " initrd=/install/initrd.gz<wait>",
    " kbd-chooser/method=us<wait>",
    " keyboard-configuration/layout=USA<wait>",
    " keyboard-configuration/variant=USA<wait>",
    " locale=en_US.UTF-8<wait>",
    " netcfg/get_domain=vm<wait>",
    " netcfg/get_hostname=vagrant<wait>",
    " grub-installer/bootdev=/dev/sda<wait>",
    " noapic<wait>",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed_path}<wait>",
    " -- <wait>",
    "<enter><wait>"
  ]
}

source "vmware-iso" "base-ubuntu-amd64" {
  headless         = var.headless
  format           = "ovf"
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
  boot_wait        = "10s"
  guest_os_type    = "ubuntu-64"
  //http_directory      = local.http_directory
  http_directory      = "http"
  ssh_password        = "ubuntu"
  ssh_port            = 22
  ssh_timeout         = "10000s"
  ssh_username        = "ubuntu"
  tools_upload_flavor = "linux"
  vmx_data = {
    "cpuid.coresPerSocket"    = "1"
    "ethernet0.pciSlotNumber" = "32"
  }
  vmx_remove_ethernet_interfaces = true
}


build {
  name        = "ubuntu"
  description = "mdx-ubuntu-1804"

  source "source.vmware-iso.base-ubuntu-amd64" {
    name             = "18.04"
    iso_url          = local.iso_url_ubuntu_1804
    iso_checksum     = "file:${local.iso_checksum_url_ubuntu_1804}"
    output_directory = "vmware_iso_ubuntu_1804_amd64"
    boot_command     = local.ubuntu_1804_boot_command
  }

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/ubuntu"]
    execute_command   = "echo 'ubuntu' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
    expect_disconnect = true
    // fileset will list files in scripts sorted in an alphanumerical way.
    scripts = fileset(".", "scripts/*.sh")
  }
}

