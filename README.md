# Devel-IPerl

[![Coverage Status](https://coveralls.io/repos/EntropyOrg/p5-Devel-IPerl/badge.png?branch=master)](https://coveralls.io/r/EntropyOrg/p5-Devel-IPerl?branch=master)
[![CPAN version](https://badge.fury.io/pl/Devel-IPerl.svg)](https://metacpan.org/pod/Devel::IPerl)

## Installation

### Dependencies

Devel::IPerl depends upon the ZeroMQ library (ZMQ) and Project Jupyter in order to work.

#### ZeroMQ

##### Debian

On Debian-based systems, you can install ZeroMQ using `apt`.

    sudo apt install libzmq3-dev 

##### macOS

If you use Homebrew on macOS, you can install ZeroMQ by using

    brew install zmq

You may also need to install `cpanm` this way by using

    brew install cpanm

##### Installing ZeroMQ without a package manager

Some systems may not have a package manager (e.g,. Windows) or you may want to
avoid using the package manager.

Make sure you have Perl, a C/C++ compiler, and a CPAN client (`cpanm`) on your
system.

Then run the following command

    cpanm --notest Alien::ZMQ::latest

It has been tested on GNU/Linux, macOS, and Windows (Strawberry Perl 5.26.1.1).

Note: There are currently issues with installing on Windows using ActivePerl
and older versions of Strawberry Perl. These are mostly due to having an older
toolchain which causes builds of the native libraries to fail.

#### Jupyter

See the [Jupyter install](http://jupyter.org/install.html) page to see how to
install Jupyter.

On Debian, you can install using `apt`:

    sudo apt install jupyter-console jupyter-notebook

If you know how to use `pip`, this may be as easy as

    pip install -U jupyter
    # or use pip3 (for Python 3) instead of pip

Make sure Jupyter is in the path by running

    jupyter --version

### Install from CPAN

    cpanm Devel::IPerl

## Running

    iperl console  # start the console

    iperl notebook # start the notebook

See the [wiki](https://github.com/EntropyOrg/p5-Devel-IPerl/wiki) for more
information and example notebooks!
