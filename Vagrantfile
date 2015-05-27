# This file requires the following vagrant plugins
# vagrant plugin install vagrant-hostsupdater

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

private_key_path = ENV.fetch(
  "PRIVATE_KEY_PATH", File.join(ENV.fetch("HOME"), ".ssh/vagrant_rsa"))

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # machine-specific settings
  config.vm.hostname = "docker-registry.v"
  config.vm.network :private_network, ip: "10.9.8.70"

  # common settings shared by all vagrant boxes for this project
  config.ssh.forward_agent = true
  config.ssh.insert_key = true
  config.ssh.private_key_path = [
    "~/.vagrant.d/insecure_private_key",
    private_key_path
  ]
  config.vm.box = "ubuntu/trusty64"
  # config.vm.network "private_network", type: "dhcp"
  # config.vm.provision "shell", path: "./provision.sh"
  # config.vm.synced_folder "./", "/vagrant", disabled: true

  if Vagrant.has_plugin?("vagrant-hostsupdater")
    config.hostsupdater.aliases = [config.vm.hostname.split(".").first]
  end

  # config.vm.provision :hostsupdate, run: 'always' do |host|
  #   host.hostname = config.vm.hostname
  #   host.manage_guest = true
  #   host.manage_host = true
  #   host.aliases = [config.vm.hostname.split(".").first]
  # end

  # if Vagrant.has_plugin?("hostmanager")
  #   puts "HAS hostmanager!"
  #   config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
  #     if vm.id
  #       `VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
  #     end
  #   end
  #   config.hostmanager.enabled = true
  #   config.hostmanager.manage_host = true
  #   config.hostmanager.ignore_private_ip = false
  #   config.hostmanager.include_offline = true
  #   config.hostmanager.aliases = [config.vm.hostname.split(".").first]
  # end

  # puts config.hostsupdater.aliases.to_s
end
