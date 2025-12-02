Debian Package Build Guide
===========================

This guide shows how to build a working Debian package for Vocal Plasma.

Prerequisites
-------------

Before building, install the required build tools:

.. code-block:: bash

    apt-get update
    apt-get install -y debhelper build-essential

**Required packages:**

- ``debhelper`` - Debian packaging helper tools (provides ``dh`` command)
- ``build-essential`` - Essential build tools (gcc, make, etc.)

**Reference:** See `Debian New Maintainers' Guide <https://www.debian.org/doc/manuals/maint-guide/>`_ for details on Debian packaging.

Build Script
------------

The ``build.sh`` script organizes outputs into ``build/output/`` within the project::

    vocal-plasma/
    ├── debian/
    ├── kokoro_tts/
    ├── build/
    │   ├── output/
    │   │   ├── vocal-plasma_0.1.1_all.deb      ← Final package
    │   │   ├── vocal-plasma_0.1.1_amd64.changes
    │   │   └── vocal-plasma_0.1.1_amd64.buildinfo
    │   └── bdist.linux-x86_64/                   ← Python wheel artifacts
    ├── build.sh                                   ← Build script
    └── ...

Using the Build Script
-----------------------

Quick Build
~~~~~~~~~~~

.. code-block:: bash

    ./build.sh

This:

1. Cleans old artifacts (``build/output/*``)
2. Runs ``dpkg-buildpackage -us -uc -d``
3. Moves ``.deb``, ``.changes``, ``.buildinfo`` to ``build/output/``
4. Shows a summary with installation instructions

Output Location
~~~~~~~~~~~~~~~

The built package is at::

    build/output/vocal-plasma_0.1.1_all.deb

Installation
~~~~~~~~~~~~

.. code-block:: bash

    dpkg -i build/output/vocal-plasma_*.deb
    apt-get install -f

The package works out of the box after installation. Test it:

.. code-block:: bash

    echo "Hello world" | speak

For KDE Plasma integration (shortcut is configured automatically):

1. Restart Plasma session
2. Select any text
3. Press ``Alt+Esc`` to hear it spoken

Build Directory Structure
------------------------------------

``build/output/``
~~~~~~~~~~~~~~~~~

Final deliverables:

- ``.deb`` - The actual Debian package
- ``.changes`` - Change metadata
- ``.buildinfo`` - Build information

``build/bdist.linux-x86_64/``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Python wheel build artifacts (created by setuptools, can be cleaned)

Cleaning Build Artifacts
-------------------------

To clean build artifacts:

.. code-block:: bash

    ./clean-artifacts.sh

The ``build.sh`` script also automatically cleans before building.

Notes
-----

- Package is always built to ``build/output/vocal-plasma_*.deb``
- If build fails, run ``./clean-artifacts.sh`` and try again
