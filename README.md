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

Grab the web_ip value, head on into a browser, and navigate to http://web_ip:8080 and you will see your running Concourse cluster's UI!

## Using the cluster

Let's look at an example of using this new cluster.

The best quick example I've found is the [Concourse.ci hello world tutorial](https://concourse.ci/hello-world.html).

Go ahead and go through this tutorial - but wherever it shows an IP address, i.e.

```
$ fly -t lite login -c http://192.168.100.4:8080
```

Substitute the IP address of your web node, i.e.

```
$ fly -t lite login -c http://my_web_node_ip:8080
```

When it prompts you for the username and password, enter "concourse" for the username and "changeme" for the password.

(these are currently the defaults for the habitat/concourse_web plan, I will make these configurable in the next iteration of this config)

Go ahead and create the hello.yml file as prompted in the tutorial, and then upload it to your cluster with

```
$ fly -t lite set-pipeline -p hello-world -c hello.yml
```

When that succeeds, head back to your browser and, if needed, navigate to http://web_ip:8080 and click the "Login" button in the upper right hand corner. Select the "main" team, then login with username: "concourse", password "changeme".


And you should see your "hello-world" pipeline! Check out the [rest of the tutorial](https://concourse.ci/hello-world.html) for info on unpausing and running your pipeline, as well as other simple pipelines! Go forth and Concourse!