jss-vagrant
===========

This is a very basic Vagrant environment that helps you stand up an Ubuntu-based JSS server for test use with the Casper Suite. I built this for the purposes of being able to quickly set up and tear down a local JSS VM for an [AutoPkg](https://autopkg.github.io/autopkg) demo I did at the [MacSysAdmin 2014 Conference](http://macsysadmin.se/2014/Wednesday.html). I was 

It has been tested with the following Vagrant providers:

* virtualbox (default provider that ships with Vagrant)
* vmware_fusion (paid VMware provider from Hashicorp)
* [digital_ocean](https://github.com/smdahlen/vagrant-digitalocean)

And has been tested with JSS versions 9.32 and 9.4. As I don't actually use the Casper Suite, I have no intention to continue testing later versions (see below, "Support").

The configuration is done with a single script, `bootstrap.sh`, which configures MySQL and Tomcat using the JSS webapp. The JSS is configured with a self-signed certificate, a more UNIX-like logging directory at `/var/log/jss`, at the default 8443 port.

The script has support for setting the JSS URL configuration, either manually via the script (which you would typically combine with an `/etc/hosts` entry), or automatically based on the IP address of the first network interface.

Setup
-----

The only required steps are to copy a `ROOT.war` file extracted from the "JSS Manual Installation" package into the `jss-app` directory of this repo. Leave the name as-is.

Optionally:

* Copy a backup of a preconfigured JSS MySQL database to a file at `data/jss_data.sql` (see guidelines in `bootstrap.sh` for how to do this).
* Tweak any additional Tomcat and Java settings in the provided `tomcat7-default` and `server.xml` environment files.

Should you need it, the MySQL root user password is `JAMF`, and the credentials for the `jamfsoftware` database are the defaults: user `jamfsoftware`, password `jamfsw03`.

Typically for testing, your backup would contain enough configuration that you can immediately enroll test clients, have distribution point(s) configured, etc. You may wish to start a clean instance from this setup and then make backups as you build up a test environment. You can store different backups wherever you wish, but the only one that gets automatically restored to the server is the one named `jss_data.sql`.


Provisioning
------------

Typically you would provision the instance only once (on initial `up`), or otherwise just destroy and rebuild the VM. The `bootstrap.sh` script was not written to be idempotent, but of course this could all be re-written with a proper configuration management provisioner.


Support
-------

I don't have plans to continue any development for this setup, as I am not using Casper in production. Hopefully, some others who administrate and test the Casper Suite might find this repo helpful.
