# Setup script for the Grid5000 SCION infrastructure

This script is intended to be used to deploy the machines and environments for the SCION Grid5000 infrastructure.
It uses a combination of the [Grid5000 API](https://api.grid5000.fr/doc/3.0/) and [ssh](https://man.openbsd.org/ssh.1).

The deployment may take a few minutes as the machines have to reboot and load the environment first.

## Usage

This script is intended to be executed in the Grid5000 intranet. You'll need your Grid5000 account with ssh access into the g5k access points
(https://www.grid5000.fr/w/Grid5000:Get_an_account).

> TODO: this script can also be modified to work outside of grid5000 but we have to authenticate against the Grid5000 API instead

Once you made sure everything works with your account, copy this script into a site in g5k e.g. lille
```bash
scp setup_scion.sh _username_@access.grid5000.fr:lille
```

Then connect to your site
```bash
ssh -J _username_@access.grid5000.fr  _username_@lille.grid5000.fr
```

And execute the script there
```bash
bash setup_scion.sh
```

It takes some time until this is completed, after it is finished you have two machines in Grid5000 in Nancy and Lille which both have a scionlab user
configured and connection to the GTS VLAN.
