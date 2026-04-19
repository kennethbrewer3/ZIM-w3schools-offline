# W3Schools - Offline Archive

A self-hosted offline reference collection of tutorials for various computer languages such as HTML, CSS, JavaScript and many others, built for use with [Kiwix](https://kiwix.org). Part of Project Nomad.

## What This Is

This project packages the [Archive of W3Schools](https://github.com/vahid-kazemi/W3Schools_offline.git) into a ZIM file that can be served locally via Kiwix. The source documents come from the [W3Schools](https://www.w3schools.com/).

The web interface has search, branch filtering, and a VIEW button for each document.

## Directory Structure

```
w3schools-archive/
  install.sh              # downloads W3Schools Archive, builds the ZIM, and optionally deploys
```

## Setup

This should be run directly on the machine hosting the Kiwix/Nomad server.

### 1. Install Dependencies

```bash
sudo apt install git unzip python3 zim-tools
```

### 2. Clone the Repo

```bash
git clone https://github.com/jrsphoto/ZIM-w3schools-offline.git
cd ZIM-w3schools-offline
chmod +x install.sh
```

### 3. Run the Installer

The simplest way is to let the script handle everything in one shot:

```bash
./install.sh \
  --deploy \
  --zim-dest=/your/kiwix/library \
  --container=your_kiwix_container
```

This will:
- Clone the full W3Schools Offline repo collection from github (~6GB)
- Build `w3schools.zim` in the current directory (this takes longer than cloning the repo)
- Copy the ZIM to your Kiwix library directory with correct ownership
- Register it with the Kiwix library XML
- Restart the Kiwix container

## Script Options

| Option | Description |
|--------|-------------|
| `--skip-clone` | Skip the clone operation, use existing files in `W3Schools_offline` |
| `--skip-zim` | Skip the ZIM build, just clone the repo |
| `--deploy` | Automatically deploy to Kiwix after building (requires `--zim-dest` and `--container`) |
| `--zim-dest=PATH` | Path to your Kiwix library directory on the host |
| `--container=NAME` | Name of your Kiwix Docker container |

## Rebuilding

If the repo is updated and you do a git pull, re-run with `--skip-download` and `--deploy`:

```bash
./install.sh --skip-download \
  --deploy \
  --zim-dest=/your/kiwix/library \
  --container=your_kiwix_container
```

The script will remove any existing entries for this ZIM from the Kiwix library before re-adding the new one, so no duplicates build up over time.

## Dependencies

- `git` -- for cloning the repo
- `unzip` -- extracts the downloaded zip
- `python3` -- generates the illustration.png icon if missing
- `zimwriterfs` -- part of the `zim-tools` package
- Docker with a running Kiwix container

