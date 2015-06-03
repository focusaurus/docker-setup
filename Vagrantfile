# Optionally install this plugin for automatic /etc/hosts updating:
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
end
