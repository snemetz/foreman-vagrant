#!/bin/sh

# Run on VM to bootstrap Foreman server
# Gary A. Stafford - 01/15/2015

foreman_version='1.8'

if ps aux | grep "/usr/share/foreman" | grep -v grep 2> /dev/null
then
    echo "Foreman appears to all already be installed. Exiting..."
else

    # Update system first
    sudo yum update -y

    # Update iptables

    # HTTP/HTTPS
    sudo /sbin/iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    sudo /sbin/iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT

    # TFTP
    sudo /sbin/iptables -A INPUT -i eth0 -m state --state NEW -m tcp -p tcp --dport 69 -j ACCEPT
    sudo /sbin/iptables -A INPUT -i eth0 -m state --state NEW -m udp -p udp --dport 69 -j ACCEPT

    # DHCP
    sudo /sbin/iptables -A INPUT -i eth0 -m state --state NEW -m udp -p udp --dport 67 -j ACCEPT
    sudo /sbin/iptables -A INPUT -i eth0 -m state --state NEW -m udp -p udp --dport 68 -j ACCEPT

    # DNS
    sudo /sbin/iptables -A INPUT -i eth0 -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
    sudo /sbin/iptables -A INPUT -i eth0 -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT

    # Foreman Proxy -- docs say REST, so this should only be TCP
    sudo /sbin/iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT

    # Temp disable firewall untill rules get fixed
    sudo service iptables stop
    sudo service ip6tables stop

    # Install Foreman for CentOS 6
    sudo rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm && \
    sudo yum -y erase puppet-agent && \
    sudo rm -f /etc/yum.repos.d/puppetlabs-pc1.repo && \
    sudo yum clean all && \
    sudo yum -y install epel-release http://yum.theforeman.org/releases/${foreman_version}/el6/x86_64/foreman-release.rpm && \
    sudo yum -y install foreman-installer foreman-libvirt && \
    sudo foreman-installer 

    # First run the Puppet agent on the Foreman host which will send the first Puppet report to Foreman,
    # automatically creating the host in Foreman's database
    sudo puppet agent --test --waitforcert=60

    # Install Foreman Providers
    yum -y install foreman-libvirt
    # Install Foreman Plugins
    yum -y install ruby193-rubygem-foreman_bootdisk ruby193-rubygem-foreman_discovery ruby193-rubygem-foreman_hooks \
                   ruby193-rubygem-foreman_dhcp_browser ruby193-rubygem-foreman_graphite \
                   ruby193-rubygem-foreman_templates ruby193-rubygem-foreman-tasks
    # Broken
    #  ruby193-rubygem-foreman_openstack_cluster - Look at web doc
    # NO RPMs, install via gem
    #  hubot_notify foreman_resources 

    # Setup r10k and sync

    # Install some optional puppet modules on Foreman server to get started...
    sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-ntp
    sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-git
    sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-vcsrepo
    sudo puppet module install -i /etc/puppet/environments/production/modules garethr-docker
    sudo puppet module install -i /etc/puppet/environments/production/modules garystafford-fig
    sudo puppet module install -i /etc/puppet/environments/production/modules jfryman-nginx
    sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-haproxy
    sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-apache
    sudo puppet module install -i /etc/puppet/environments/production/modules puppetlabs-java
fi
