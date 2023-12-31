
# TeXLive (texlive)

A feature to use TeXLive

## Example Usage

```json
"features": {
    "ghcr.io/takker99/devcontainer-features/texlive:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| scheme | Choose texlive scheme. | string | basic |
| srcfiles | Whether to install source files | boolean | false |
| docfiles | Whether to install documentation files | boolean | false |
| collections | Comma separated list of collections to install | string | - |

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.

---
_Ported from https://github.com/devcontainers/features/blob/3ea4d6bbd7864bcf7b5a91fdeeb66e4f5a6f46c0/src/node/NOTES.md?plain=1#L21-L25_

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/takker99/devcontainer-features/blob/main/src/texlive/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
