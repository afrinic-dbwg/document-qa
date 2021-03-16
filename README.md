# DBWG Document QA

GitHub action for document quality assurance CI pipeline.

## About

This repository provides a docker image and associated GitHub action definition
for testing working group documents against document quality assurance standards.

The following tests are provided:

-   Spelling checks using [Hunspell](https://github.com/hunspell/hunspell),
    including support for the [WG custom word-list](https://github.com/afrinic-dbwg/document-qa/blob/master/dictionary)
    and a repository specific local word-list to easily incorporate technical
    terms;
-   Markdown style guide enforcement using
    [`markdownlint-cli`](https://github.com/igorshubovych/markdownlint-cli),
    based on the [WG markdown style guide](https://github.com/afrinic-dbwg/document-qa/blob/master/style-guide.md)

## Usage

### As a GitHub action

Add `use: afrinic-dbwg/document-qa@release` to a step in your workflow
definition.

Using [`act`](https://github.com/nektos/act) to run the workflow from your local
machine is supported.

Repositories created from the [`work-item-template`](https://github.com/afrinic-dbwg/work-item-template)
repository will be configured to use this action out of the box.

### As a standalone container

The built container can be used directly with the `docker` run-time to perform
local checks.

``` sh
docker pull ghcr.io/afrinic-dbwg/document-qa:release
docker run --rm \
           --tty \
           --volume "$(pwd):/opt/working" \
           ghcr.io/afrinic-dbwg/document-qa:release
```

The same image can be used interactively from the CLI as an interactive spell
checker.

``` sh
docker pull ghcr.io/afrinic-dbwg/document-qa:release
docker run --rm \
           --tty \
           --interactive \
           --volume "$(pwd):/opt/working" \
           ghcr.io/afrinic-dbwg/document-qa:release \
           --interactive  # yes, that's another interactive, not a typo
```

## License

All contents, including user contributions are licensed under the
MIT license, available in the root of the repository.
