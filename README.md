# vlsi-toolbox

Ubuntu-based **VLSI / EDA toolbox container** intended for use with **Distrobox**.

This image provides a large, batteries-included environment for digital and mixed-signal VLSI work, including open-source synthesis, simulation, P&R, and layout tools. It is designed to be used *interactively* as a development environment rather than as a minimal runtime container.

---

## 📦 Image

The image is published on GitHub Container Registry:

```
ghcr.io/xelef2000/vlsi-toolbox
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

> ⚠️ **Note**
> There is **no multi-arch manifest**. Each image is already ~8 GB, so architectures are published separately.

---

## 🐳 Intended usage: Distrobox

This container is meant to be used with **Distrobox**

### Create the container

For **amd64** hosts:

```
distrobox create \
  --name vlsi-toolbox \
  --image ghcr.io/xelef2000/vlsi-toolbox:latest-amd64
```

For **arm64** hosts:

```
distrobox create \
  --name vlsi-toolbox \
  --image ghcr.io/xelef2000/vlsi-toolbox:latest-arm64
```


---

## 🛠️ Included toolchains

### Digital / RTL

* **Yosys** (+ `yosys-dev`)
* **Icarus Verilog** (`iverilog`)
* **Verilator**
* **GHDL** (VHDL)
* **gtkterm**
* **vrtlmod** (built from source; requires LLVM/Clang 15 and SystemC 2.3.3, both included)
* **TMRG** (Triple Modular Redundancy Generator; installed from CERN GitLab)

### Physical design

* **OpenROAD** (built from source)
* **Magic VLSI**
* **KLayout** (built from source, Qt5 GUI enabled)

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

This image is **large** (≈8 GB per architecture).

That is intentional:

* Tools are built from source where required
* GUI support is included
* The goal is *completeness*, not minimal size

---

## 📄 License

This container bundles many third‑party open‑source tools.

Each tool retains its **original license**. Refer to the respective upstream projects for license details.

---

## 🤝 Contributing

Issues and improvements are welcome. If you have additional tools or fixes that make sense for a general-purpose VLSI toolbox, feel free to open a PR or issue.
