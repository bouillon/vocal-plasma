Debian Package Build Guide
==========================

Prerequisites::

    apt-get install -y debhelper build-essential

Build
-----

::

    ./build

Runs ``dpkg-buildpackage -us -uc -b -d``, artifacts land in ``dist/``::

    dist/vocal-plasma_0.1.2_all.deb

Install
-------

::

    dpkg -i dist/vocal-plasma_*.deb

Test: ``echo hello | speak``; select text and press ``Alt+Esc``.

Release
-------

Publish the current version to GitHub (tag + deb + sha256)::

    GITHUB_TOKEN=... ./release

Clean
-----

::

    ./clean-artifacts.sh
