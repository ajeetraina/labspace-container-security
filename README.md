
# Labspace - Creating a More Secure Production with Containers

<img width="1464" height="991" alt="image" src="https://github.com/user-attachments/assets/3c409ab7-a9b3-47c3-ac5e-9cbeb53eda81" />


Welcome to this labspace on container security and Docker Hardened Images! This workshop
will take you from surfacing vulnerabilities in an unverified base image all the way to
a fully hardened, policy-compliant, distroless production image with built-in supply chain
attestations.

## Learning objectives

In this workshop we will learn:

- How to surface CVE exposure using Docker Scout on a real-world Node.js app
- How to apply 8 container security best practices to progressively harden an image
- How to use multi-stage builds to keep production images lean and clean
- How to run containers as non-root with read-only filesystems and dropped capabilities
- How to scan continuously with Docker Scout — locally, in CI, and at the registry
- How to manage secrets safely using BuildKit and avoid common leakage patterns
- How to migrate from a standard base image to Docker Hardened Images (DHI)
- How to inspect DHI attestations — SBOM, VEX, FIPS, SLSA provenance
- How to integrate DHI VEX documents with external scanners like Grype and Trivy

## Launch the Labspace


```bash
docker compose -f oci://ajeetraina777/labspace-container-security up
```

and then open your browser to [http://localhost:3030](http://localhost:3030)

### Cloning the repo locally

- Clone the repo
- Run the following command:

```bash
CONTENT_PATH=$PWD docker compose up --watch
```

### Using the Docker Desktop extension

If you have the Labspace extension installed (`docker extension install dockersamples/labspace-extension` if not), you can also click [this link](https://open.docker.com/dashboard/extension-tab?extensionId=dockersamples/labspace-extension&location=ajeetraina/labspace-container-secutiry&title=container-security) to launch the Labspace.

## Contributing

If you find something wrong or something that needs to be updated, feel free to submit a PR. If you want to make a larger change, feel free to fork the repo into your own repository.

**Important note:** If you fork it, you will need to update the GHA workflow to point to your own Hub repo.

1. Clone this repo

2. Start the Labspace in content development mode:

    ```bash
    # On Mac/Linux
    CONTENT_PATH=$PWD docker compose up --watch

    # On Windows with PowerShell
    $Env:CONTENT_PATH = (Get-Location).Path; docker compose up --watch
    ```

3. Open the Labspace at http://localhost:3030.

4. Make the necessary changes and validate they appear as you expect in the Labspace

    Be sure to check out the [docs](https://github.com/dockersamples/labspace-infra/tree/main/docs) for additional information and guidelines.
