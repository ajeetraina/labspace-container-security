# Setup

## 1. Docker org setup

::variableDefinition[org]{prompt="What is your Docker Organization?"}

## 2. DHI tier selection

DHI offers both a **free tier** and a **paid tier**.

- **Free tier** — images at the `dhi.io` registry, no Docker Hub subscription needed
- **Paid tier** — images mirrored into your org on Docker Hub

> **How to choose?** Use the free tier unless you have a paid plan and have the
> `dhi.io/node` image mirrored in your organization.

::variableSetButton[Use the free tier]{variables="tier=free,dhiPrefix=dhi.io/"}

::variableSetButton[Use the paid tier ($$org$$)]{variables="tier=paid,dhiPrefix=$$org$$/dhi-"}

## 3. Docker login

```bash
docker login
```

:::conditionalDisplay{variable="tier" requiredValue="free"}
Also log in to the `dhi.io` registry:

```bash
docker login dhi.io
```
:::

## 4. Configure Docker Scout organization

```bash
docker scout config organization $$org$$
```

## 5. Clone and bootstrap the project

The setup script applies a patch that deliberately introduces a vulnerable state —
old base image and downgraded dependencies — so we can demonstrate the full security
journey from the bottom up.

```bash terminal-id=main
git clone https://github.com/dockersamples/catalog-service-node
cd catalog-service-node
./demo/sdlc-e2e/setup.sh
```

```bash terminal-id=main
docker rm $(docker ps -a -q) -f
clear
```

```bash terminal-id=npm
cd catalog-service-node
npm install
clear
```

Pre-build the initial image so Scout has something to analyse:

```bash terminal-id=build
cd catalog-service-node
docker build -t catalog-service --sbom=true --provenance=mode=max .
clear
```
