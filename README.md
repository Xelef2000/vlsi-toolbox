# vlsi-toolbox

Ubuntu-based **VLSI / EDA toolbox container** intended for use with **Distrobox**.

This repository publishes two Ubuntu-based containers for digital and mixed-signal VLSI work:

* `vlsi-toolbox`: full image with GUI tools included
* `vlsi-toolbox-light`: lighter image without GUI-only applications, while keeping command-line flows such as OpenROAD

Both are designed to be used *interactively* as development environments with **Distrobox**.

---

## 📦 Images

The images are published on GitHub Container Registry:

```
ghcr.io/xelef2000/vlsi-toolbox
ghcr.io/xelef2000/vlsi-toolbox-light
```

### Supported architectures

There are **separate images per architecture**:

* `amd64`
* `arm64`

Examples:

```
v1.1.1-amd64
v1.1.1-arm64
latest-amd64
latest-arm64
```

The light image follows the same architecture-specific tag scheme on `ghcr.io/xelef2000/vlsi-toolbox-light`:

```
v1.1.1-amd64
v1.1.1-arm64
latest-amd64
latest-arm64
```

Release builds also publish compatibility tags on `ghcr.io/xelef2000/vlsi-toolbox`, for example:

```
v1.1.1-light-amd64
v1.1.1-light-arm64
latest-light-amd64
latest-light-arm64
```

> ⚠️ **Note**
> There is **no multi-arch manifest**. Images are published separately per architecture.

---

## 🐳 Intended usage: Distrobox

This container is meant to be used with **Distrobox**

### Create the container

For the full image on **amd64** hosts:

```
distrobox create \
  --name vlsi-toolbox \
  --image ghcr.io/xelef2000/vlsi-toolbox:latest-amd64
```

For the full image on **arm64** hosts:

```
distrobox create \
  --name vlsi-toolbox \
  --image ghcr.io/xelef2000/vlsi-toolbox:latest-arm64
```

For the light image on **amd64** hosts:

```
distrobox create \
  --name vlsi-toolbox-light \
  --image ghcr.io/xelef2000/vlsi-toolbox-light:latest-amd64
```

For the light image on **arm64** hosts:

```
distrobox create \
  --name vlsi-toolbox-light \
  --image ghcr.io/xelef2000/vlsi-toolbox-light:latest-arm64
```

---

## 🛠️ Included toolchains

### Image variants

* **Full image**: includes everything below, including GUI apps such as **KLayout**, **gtkterm**, and **xdot**
* **Light image**: removes **KLayout**, **gtkterm**, and **xdot**
* **OpenROAD** is included in both images; in the light image it is built with `-DBUILD_GUI=OFF`

### Digital / RTL

* **Yosys** (+ `yosys-dev`)
* **Icarus Verilog** (`iverilog`)
* **Verilator**
* **GHDL** (VHDL)
* **vrtlmod** (built from source; requires LLVM/Clang 15 and SystemC 2.3.3, both included)
* **TMRG** (Triple Modular Redundancy Generator; installed from CERN GitLab)

### Physical design

* **OpenROAD** (built from source)
* **Magic VLSI**
* **KLayout** (full image only; built from source, Qt5 GUI enabled)

### Analog / mixed-signal

* **ngspice**

### FPGA / tooling

* **apio**
* **yowasp-yosys**
* **yowasp-nextpnr-ice40**

### Dependency management

* **Bender** (ETH Zurich / PULP Platform)

---

## 🧰 Development environment

### Languages & ecosystems

* GCC / G++ toolchain
* Python 3 + `pip` (system installs enabled)
* Node.js + npm
* Ruby
* Tcl / Tk
* Haskell (`ghc`, `stack`)


---

## ⚠️ Image size

The full image is **large** (≈8 GB per architecture).

That is intentional:

* Tools are built from source where required
* GUI support is included
* The goal is *completeness*, not minimal size

The light image is intended to reduce size and dependency weight by removing GUI-only applications while preserving CLI-oriented implementation flows.

---

## 📁 Repository layout

Dockerfiles now live in per-image folders:

* `docker/full/Dockerfile`
* `docker/light/Dockerfile`

---

## 📄 License

This container bundles many third‑party open‑source tools.

Each tool retains its **original license**. Refer to the respective upstream projects for license details.

---

## 🤝 Contributing

Issues and improvements are welcome. If you have additional tools or fixes that make sense for a general-purpose VLSI toolbox, feel free to open a PR or issue.
