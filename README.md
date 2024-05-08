<!-- markdownlint-disable MD024 -->

# Dev Container Features

[![Release](https://img.shields.io/github/release/bartventer/arch-devcontainer-features.svg)](https://github.com/bartventer/arch-devcontainer-features/releases/latest)
[![Release Workflow](https://github.com/bartventer/arch-devcontainer-features/actions/workflows/release.yaml/badge.svg)](https://github.com/bartventer/arch-devcontainer-features/actions/workflows/release.yaml)
[![Test Workflow](https://github.com/bartventer/arch-devcontainer-features/actions/workflows/test.yaml/badge.svg)](https://github.com/bartventer/arch-devcontainer-features/actions/workflows/test.yaml)
[![License](https://img.shields.io/github/license/bartventer/arch-devcontainer-features.svg)](LICENSE)

<!-- markdownlint-disable MD033 -->
<table style="width: 100%; border-style: none;">
    <tr>
        <td style="width: 140px; text-align: center;">
            <a href="https://github.com/JotaRandom/archlinux-artwork">
                <img width="128px" src="https://raw.githubusercontent.com/JotaRandom/archlinux-artwork/a9029989166ef42e10251f9d0f0fd09e60be2f31/icons/archlinux-icon-crystal-256.svg" alt="Arch Linux logo"/>
            </a>
        </td>
        <td>
            <strong>Development Container 'Features'</strong><br />
            <i>A set of simple and reusable Features for Arch Linux development containers.</i><br />
        </td>
    </tr>
</table>
<!-- markdownlint-enable MD033 -->

This repository contains a _collection_ of features curated by [@bartventer](https://github.com/bartventer). While most of these features are built for Arch Linux, please refer to the "OS Support" section of each feature for specific operating system compatibility.

## Table of Contents

-   [Collected Features](#collected-features)
    -   [common-utils](#common-utils)
    -   [aws-cli](#aws-cli)
    -   [docker-in-docker](#docker-in-docker)
    -   [docker-outside-of-docker](#docker-outside-of-docker)
    -   [terraform](#terraform)
-   [Contributing](#contributing)
-   [License](#license)
-   [Trademarks](#trademarks)

## Collected Features

### common-utils

Common Utilities installs a set of common command line utilities, Oh My Zsh!, and sets up a non-root user on Arch Linux. The `additionalPackages` option simplifies the inclusion of packages that would otherwise need separate features in non-Arch OS.

#### usage

```json
"features": {
    "ghcr.io/bartventer/arch-devcontainer-features/common-utils:1": {
        "installZsh": true,
        "additionalPackages": "go nodejs npm",
        "configureZshAsDefaultShell": false,
        "installOhMyZsh": true,
        "installOhMyZshConfig": true,
        "username": "automatic",
        "userUid": "automatic",
        "userGid": "automatic"
    }
}
```

Additional options can be found in the [feature documentation](src/common-utils/README.md).

### aws-cli

AWS CLI installs the AWS CLI along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

#### usage

```json
"features": {
    "ghcr.io/bartventer/arch-devcontainer-features/aws-cli:latest": {
        "installSam": "standalone",
        "samVersion": "latest",
    }
}
```

Additional options can be found in the [feature documentation](src/aws-cli/README.md).

### docker-in-docker

Docker in Docker installs Docker and Docker Compose in a Docker container. This is useful for running Docker commands inside a Docker container.

#### usage

```json
"features": {
    "ghcr.io/bartventer/arch-devcontainer-features/docker-in-docker:latest": {
        "version": "latest"
    }
}
```

Additional options can be found in the [feature documentation](src/docker-in-docker/README.md).

### docker-outside-of-docker

Docker outside of Docker re-uses the host docker socket, adding the Docker CLI to a container. This feature invokes a script to enable using a forwarded Docker socket within a container to run Docker commands.

#### usage

```json
"features": {
    "ghcr.io/bartventer/arch-devcontainer-features/docker-outside-of-docker:latest": {
        "version": "latest",
        "dockerDashComposeVersion": "v2",
        "installDockerBuildx": true,
        "installDockerComposeSwitch": true
    }
}
```

Additional options can be found in the [feature documentation](src/docker-outside-of-docker/README.md).

### terraform

Terraform installs the Terraform CLI and optionally Terragrunt and TFLint. Auto-detects the latest version and installs needed dependencies.

#### usage

```json
"features": {
    "ghcr.io/bartventer/arch-devcontainer-features/terraform:latest": {
        "installTerragrunt": true,
        "installTflint": true,
        "installSentinel": true,
        "installTFsec": true,
        "installTerraformDocs": true
    }
}
```

Additional options can be found in the [feature documentation](src/terraform/README.md).

## Contributing

All contributions are welcome! Open a pull request to request a feature or submit a bug report.

## License

This project is licensed under the [MIT License](LICENSE).

## Trademarks

The Arch Linux logo is a recognized trademark of Arch Linux. See the [Arch Linux website](https://archlinux.org/) for acceptable use and restrictions. The logo used in this README.md is sourced from [this repository](https://github.com/JotaRandom/archlinux-artwork) and is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License](https://creativecommons.org/licenses/by-nc-sa/3.0/).
