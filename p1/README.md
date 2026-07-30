# Inception of Things - P1

## Requirements

Required tools:

- Vagrant
- VirtualBox
- kubectl
- Git

Before starting this part, check that the required tools are installed on the host machine:

```bash
vagrant --version
VBoxManage --version
kubectl version --client
git --version
```

## General Idea

Part 1 uses Vagrant and VirtualBox to create two virtual machines:

```text

  |
  | Vagrant + VirtualBox
  |
  |-- VM 1 : icaharelS
  |       IP 192.168.56.110
  |       K3s server
  |
  `-- VM 2 : icaharelSW
          IP 192.168.56.111
          K3s agent
```

The first VM runs K3s in server mode. The second VM runs K3s in agent mode and joins the server.

## Useful Commands

Run Vagrant commands from the `p1` directory:

```bash
cd p1
```

Start the virtual machines:

```bash
vagrant up
```

Show the current VM status:

```bash
vagrant status
```

Connect to the server VM:

```bash
vagrant ssh icaharelS
```

Connect to the worker VM:

```bash
vagrant ssh icaharelSW
```

Run provisioning scripts again:

```bash
vagrant provision
```

Run provisioning for one VM only:

```bash
vagrant provision icaharelS
vagrant provision icaharelSW
```

Stop the virtual machines:

```bash
vagrant halt
```

Restart the virtual machines:

```bash
vagrant reload
```

Destroy the virtual machines:

```bash
vagrant destroy
```

Check the Kubernetes nodes from the server VM:

```bash
vagrant ssh icaharelS
kubectl get nodes
```
