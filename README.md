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
* Access to the Habitat AWS account (talk to the Chef help desk)
* AWS IAM account on the Habitat AWS account
* AWS access key associated with your IAM user on the Habitat AWS account
* AWS secret key associated with your IAM user on the Habitat AWS account
* Access to habitat team 1password account (talk to a current Habitat team member)

## Setup

### Cloning the Repo

Go ahead and clone this repo

```
$ git clone git@github.com:habitat-sh/ci-terraform.git
```

### Setting up your keys

We will use a shared Habitat server admin key to access the nodes in this Concourse cluster.

**Private habitat-srv-admin key**

* Head to the team Habitat vault
* Click on "habitat-srv-admin - srv admin"
* Click the download button
* Place the downloaded file in ~/.aws

**Public habitat-srv-admin key**

* Head back to the team Habitat vault
* Click on "habitat-srv-admin.pub - srv admin"
* Click the download button
* Place the downloaded file in ~/.aws

### Setting up your Certificates

Currently, we use the acceptance SSL cert for our concourse environment.

* Head over the the Habitat team 1Password account
* Head to the Shared vault
* Click on "*.acceptance.habitat.sh SSL Cert"

**ssl_private_key**

* Find the line that looks like this:
  ```
  ==star_acceptance_habitat_sh.key==
  ```
* Now copy everything below that line starting with
  ```
  -----BEGIN PRIVATE KEY-----
  ```
  to
  ```
  -----END PRIVATE KEY-----
  ```
* Head back to your cloud-environments repo on your workstation and create a new file
  ```
  $ vim ssl_private_key
  ```
* Now paste what you just copied into that file, save, and close. (Make sure that "-----BEGIN PRIVATE KEY-----" and "----END PRIVATE KEY-----" are on separate lines!)

**ssl_certificate**

* Now head back to the "*.acceptance.habitat.sh SSL Cert" in the team Habitat vault
* Find the line that looks like this:
  ```
  ==star_acceptance_habitat_sh.crt==
  ```
* Now copy everything below that line starting with
  ```
  -----BEGIN CERTIFICATE-----
  ```
  to
  ```
  -----END CERTIFICATE-----
  ```
* Head back to your cloud-environments repo on your workstation and create a new file
    ```
    $ vim ssl_certificate
    ```
* Now paste what you just copied into that file, save, and close. (Make sure that "-----BEGIN CERTIFICATE-----" and "----END CERTIFICATE-----" are on separate lines!)

**ssl_cert_chain**

* Now head back to the "*.acceptance.habitat.sh SSL Cert" in the team Habitat vault
* Find the line that looks like this:
  ```
  ==star_acceptance_habitat_sh.cacert==
  ```
* Now copy everything below that line starting with
  ```
  -----BEGIN CERTIFICATE-----
  ```
  to
  ```
  -----END CERTIFICATE-----
  ```
* Head back to your cloud-environments repo on your workstation and create a new file
  ```
  $ vim ssl_cert_chain
  ```
* Now paste what you just copied into that file, save, and close.  (Make sure that "-----BEGIN CERTIFICATE-----" and "----END CERTIFICATE-----" are on separate lines!)

### Setting up your terraform.tfvars file

Copy terraform.tfvars.example into a new terraform.tfvars file

```
$ cp terraform.tfvars.example terraform.tfvars
```

Now open up the terraform.tfvars file and update it with your appropriate values

(Note - for the dns_zone_id, log into the Habitat AWS account, head to Route 53, find the habitat.sh hosted zone, then copy the id of that hosted zone)

### Apply your Terraform config!

Install the required Terraform plugins with:

```
$ terraform init
```

Now run:

```
$ terraform apply
```

When it complete, you should see output similar to this:

```
db_ip = 54.187.22.81
elb_dns = concourse-elb-491563880.us-west-2.elb.amazonaws.com
web_ip = 34.223.253.118
worker_ips = [
    34.210.79.26,
    54.244.82.12,
    54.202.246.246
]
```

Now open up your browser and head to https://concourse.habitat.sh you will see your running Concourse cluster's UI!

## Using the cluster

Let's look at an example of using this new cluster.

The best quick example I've found is the [Concourse.ci hello world tutorial](https://concourse.ci/hello-world.html).

Go ahead and go through this tutorial - but wherever it shows an IP address, i.e.

```
$ fly -t hab-concourse login -c http://192.168.100.4:8080
```

Substitute in https://concourse.acceptance.habitat.sh, i.e.

```
$ fly -t hab-concourse login -c https://concourse.acceptance.habitat.sh
```

When it prompts you for the username and password, enter the values you defined in your terraform.tfvars file.

Go ahead and create the hello.yml file as prompted in the tutorial, and then upload it to your cluster with

```
$ fly -t hab-concourse set-pipeline -p hello-world -c hello.yml
```

When that succeeds, head back to your browser and, if needed, navigate to https://concourse.acceptance.habitat.sh and click the "Login" button in the upper right hand corner. Select the "main" team, then login with the username and password you defined in your terraform.tfvars file.

And you should see your "hello-world" pipeline! Check out the [rest of the tutorial](https://concourse.ci/hello-world.html) for info on unpausing and running your pipeline, as well as other simple pipelines! Go forth and Concourse!