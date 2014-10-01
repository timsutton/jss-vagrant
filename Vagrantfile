# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'puphpet/ubuntu1404-x64'

  config.vm.provider :digital_ocean do |provider, override|
    override.vm.box = 'digital_ocean'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
    provider.image = 'Ubuntu 14.04 x64'
    # Use rsync for cloud provider(s), since we have no local VM sharing available
    # (this overrides the default shared folder)
    override.vm.synced_folder ".", "/vagrant", type: "rsync"

    override.ssh.private_key_path = '~/.ssh/id_rsa'
    provider.token = 'YOUR_TOKEN_HERE'
    # If you want to point to an existing SSH key on Digital Ocean,
    # specify its name here
    # provider.ssh_key_name = "MySecretKeyName"
  end

  config.vm.provision "shell", path: "scripts/bootstrap.sh"

  # If not using a cloud provider, optionally configure a fixed private IP,
  # for example if you'd like to keep a local /etc/hosts entry for it.
  # With VirtualBox, I seem to require the private network - using the
  # default NAT'ed IP of the guest doesn't seem to respond.
  # config.vm.network "private_network", ip: "192.168.60.2"
end
