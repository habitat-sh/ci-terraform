# ci-terraform

```
$ terraform apply
$ ssh concourse_web
$ mkdir -p keys/web keys/worker
$ ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
$ ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''
$ ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''
$ cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
$ cp ./keys/web/tsa_host_key.pub ./keys/worker

sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/authorized_worker_keys

sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/session_signing_key

sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/session_signing_key.pub

sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/tsa_host_key

sudo hab file upload concourse-web.default $(date +%s) ~/keys/web/tsa_host_key.pub

sudo hab file upload concourse-worker.default $(date +%s) ~/keys/worker/worker_key.pub

sudo hab file upload concourse-worker.default $(date +%s) ~/keys/worker/worker_key

sudo hab file upload concourse-worker.default $(date +%s) ~/keys/worker/tsa_host_key.pub
```