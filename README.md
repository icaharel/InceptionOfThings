# Inception of Things

Inception of Things is a system administration project focused on a first practical introduction to Kubernetes.

The goal is to build several small environments using Vagrant, K3s, K3d and Argo CD. Each part introduces a new layer of Kubernetes usage, from creating virtual machines to deploying applications automatically.

## Project Structure

```text
.
|-- p1
|-- p2
|-- p3
`-- bonus
```

## Parts

### Part 1: K3s and Vagrant

Create two virtual machines with Vagrant:

- one K3s server / controller
- one K3s agent / worker

This part introduces basic virtual machine provisioning and the creation of a minimal K3s cluster.

### Part 2: K3s and Applications

Create one K3s server and deploy three simple web applications.

The applications must be exposed through Kubernetes Ingress and selected depending on the request host.

### Part 3: K3d and Argo CD

Use K3d instead of Vagrant to run a Kubernetes environment with Docker.

Argo CD is used to automatically deploy an application from a public GitHub repository. Updating the application version in GitHub must update the running application in the cluster.

### Bonus: GitLab

Add a local GitLab instance and make the Part 3 workflow work with it.

The bonus is evaluated only if all mandatory parts are complete and working.

## Notes

Each part has its own directory and can contain its own scripts, configuration files and README.

This project is not meant to cover all of Kubernetes. It focuses on understanding the basic concepts needed to create, connect and deploy to small Kubernetes environments.
