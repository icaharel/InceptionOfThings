# P3 Infrastructure

This first P3 step prepares the local Kubernetes environment required for Argo CD.

## Run

From the `p3` directory:

```sh
vagrant up
```

Or, from inside the VM:

```sh
sh /vagrant/scripts/setup.sh
```

The setup script:

- installs Docker, kubectl, k3d, curl and git when missing;
- creates a fresh K3d cluster named `iot-p3`;
- creates the `argocd` and `dev` namespaces;
- installs Argo CD in the `argocd` namespace.

If you need to recreate the cluster from scratch:

```sh
RESET_CLUSTER=1 sh /vagrant/scripts/setup.sh
```

## Verify

```sh
docker ps
k3d cluster list
kubectl get nodes
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
```

## Open Argo CD

From the `p3` directory:

```sh
vagrant ssh
```

Then, inside the VM:

```sh
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8081:443
```

Then open on the host:

```text
https://localhost:8081
```

The username is `admin`. The setup script prints the initial password at the end.

## GitOps application

The directory `p3/gitops` is the content that must be pushed to your public GitHub repository.

Expected GitHub repository layout:

```text
.
`-- manifests
    `-- deployment.yaml
```

The first version uses:

```text
wil42/playground:v1
```

After your public GitHub repository is ready, deploy the Argo CD application from inside the VM:

```sh
REPO_URL=https://github.com/<login>/<repo>.git sh /vagrant/scripts/deploy_app.sh
```

Test the deployed application:

```sh
sh /vagrant/scripts/test_app.sh
```

To test the update, change the image in your GitHub repository:

```text
wil42/playground:v1
```

to:

```text
wil42/playground:v2
```

Then wait for Argo CD and rerun:

```sh
sh /vagrant/scripts/test_app.sh
```
