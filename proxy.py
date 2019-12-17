#!/usr/bin/env python
import subprocess
import dockerd
import uptime
import tfutil
import slack

# Configure slack connection
slack.set_webhook('${slack_hook}')

# Send a message to slack to announce that we've come up.
slack.message("proxy instance (${hostname}) is trying to come up.")

# Load system daemons
tfutil.init()

# Add admin to docker group to call docker without sudo.
tfutil.add_docker_user("admin")

# Set the host name
tfutil.set_hostname('${hostname}')

# Create Authorized Keys
tfutil.create_authorized_keys("""${authorized_keys}""")

# Create Swap
tfutil.create_swap(int('${swapsize}'))

# Set up Docker Daemon with a label
dockerd.set_engine_label("proxy")

# And restart docker
dockerd.restart()
dockerd.wait_for_dockerd_up()

# Send a message to slack to announce that we've come up.
slack.message("proxy instance (${hostname}) has come up in " + str(uptime.uptime()) + " seconds.")

# Create /etc/squid/passwords file
subprocess.check_call(["mkdir", "-p", "/etc/squid"])
subprocess.check_call(["touch", "/etc/squid/passwords"])
subprocess.check_call(["htpasswd", "-b", "/etc/squid/passwords", '${proxy_username}', '${proxy_password}'])

# Start squid process
subprocess.check_call([
    "docker",
    "run",
        "--name=squid",
        "-d",
        "--restart=always",
        "--publish=3128:3128",
        "--volume=/srv/docker/squid/cache:/var/spool/squid",
        "--volume=/etc/squid/squid.conf:/etc/squid/squid.conf",
        "--volume=/etc/squid/passwords:/etc/squid/passwords",
        "sameersbn/squid:3.5.27-2"
])

# Send a message to slack to announce that we've come up.
slack.message("proxy instance (${hostname}) has finished starting proxy in " + str(uptime.uptime()) + " seconds.")

# System update
subprocess.check_call(["/etc/cron.daily/system-update.sh"])
