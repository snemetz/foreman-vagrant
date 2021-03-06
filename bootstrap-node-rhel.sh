#!/bin/sh

# Run on VM to bootstrap Puppet Agent RHEL-based Linux nodes
# Gary A. Stafford - 01/15/2015

if ps aux | grep "puppet agent" | grep -v grep 2> /dev/null
then
    echo "Puppet Agent is already installed. Moving on..."
else
    # Update system first
    #sudo yum update -y

    # Install Puppet for CentOS 6
    sudo rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm && \
    sudo yum -y erase puppet-agent && \
    sudo rm -f /etc/yum.repos.d/puppetlabs-pc1.repo && \
    sudo yum clean all && \
    sudo yum -y install puppet

    # Add agent section to /etc/puppet/puppet.conf (sets run interval to 120 seconds)
    echo "" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null && \
    echo "    server = theforeman.example.com" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null && \
    echo "    runinterval = 30m" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null

    sudo service puppet stop
    sudo service puppet start

    sudo puppet resource service puppet ensure=running enable=true
    sudo puppet agent --enable

    # Unless you have Foreman autosign certs, each agent will hang on this step until you manually
    # sign each cert in the Foreman UI (Infrastrucutre -> Smart Proxies -> Certificates -> Sign)
    # alternative, run manually on each host, after provisioning is complete...
    #sudo puppet agent --test --waitforcert=60
fi
