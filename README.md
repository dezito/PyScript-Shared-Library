# PyScript Shared Library

Shared library for Home Assistant PyScript projects.

This repository contains reusable Python modules shared between multiple PyScript projects, such as **BattMind** and **Cable Juice Planner**. It allows common functionality to be maintained in one place while keeping the individual projects smaller and easier to maintain.

## Features

* Shared utility modules
* Home Assistant helper functions
* Time and date helper functions
* YAML and file handling
* Notification helpers
* Translation helpers
* Performance and benchmark helpers
* Automatic installation and updates
* Hardlink-based installation to avoid duplicate files

## Installation

Run the installation script from your Home Assistant terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/dezito/PyScript-Shared-Library/main/scripts/update_library.sh | bash
```

The script will automatically:

- Clone the repository if it is not already installed.
- Update it to the latest version if it already exists.
- Install the shared modules.
- Recreate all required hardlinks.

```text
/config/pyscript/modules/dezito_pyscript
```

## Updating

To update to the latest version:

```bash
bash /config/PyScript-Shared-Library/scripts/update_library.sh
```

The update script always installs the newest version from the **main** branch.

## Recreate Hardlinks

If the hardlinks need to be recreated without downloading the repository again:

```bash
bash /config/PyScript-Shared-Library/scripts/recreate_hardlinks_shared_library.sh
```

## Uninstall

To remove the shared library modules:

```bash
bash /config/PyScript-Shared-Library/scripts/uninstall_library.sh
```

To also remove the repository:

```bash
bash /config/PyScript-Shared-Library/scripts/uninstall_library.sh --remove-repository
```

## Importing Modules

Import shared modules using the `dezito_pyscript` namespace.

Example:

```python
from dezito_pyscript.filesystem import load_yaml
from dezito_pyscript.history import History
from dezito_pyscript.utils import *
from dezito_pyscript.mytime import *
```

## Repository Structure

```text
PyScript-Shared-Library/
├── pyscript/
│   └── modules/
│       └── dezito_pyscript/
└── scripts/
```

## Used By

* BattMind
* Cable Juice Planner

## License

This project is licensed under the MIT License.
