# Concourse in Terraform

Ready to set up a Concourse Cluster with Terraform?  Let's go!

## What you get

When you apply this Terraform config, you will get
* One AWS security group for your data note
* One AWS security group for your web node and worker nodes
* One Concourse web node (running habitat/concourse-web)
* One Concourse data node (running core/postgresql at the moment)
* Three Concourse worker nodes (running habitat/concourse-worker)

## Using this Config

### Pre-reqs
* AWS account
* AWS access key
* AWS secret key
* AWS keypair
* Private half of AWS keypair accessible on your local workstation

## Setup

Go ahead and clone this repo

```
$ git clone git@github.com:habitat-sh/ci-terraform.git
```

Copy terraform.tfvars.example into a new terraform.tfvars file

```
$ cp terraform.tfvars.example terraform.tfvars
```

Open up the terraform.tfvars file, update the file with the appropriate values for your aws access key, secret key, etc. Save and close the file.

Now run:

```
$ terraform apply
```

When it complete, you should see output similar to this:

```
db_ip = 54.191.27.244
web_ip = 54.203.156.209
worker_ips = [
    35.165.129.14,
    34.217.131.0,
    34.217.10.138
]
```

Grab the web_ip value, head on into a browser, and navigate to https://web_ip:8080 and you will see your running Concourse cluster's UI!