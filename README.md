## Usage

    sudo apt-get install libzmq3-dev ipython ipython-notebook
    ipython profile create perl
    cp -p profile/ipython_config.py $(ipython locate profile perl)/ipython_config.py
    PERL5LIB="lib:$PERL5LIB" ipython console --profile perl  # start the console
    PERL5LIB="lib:$PERL5LIB" ipython notebook --profile perl # start the notebook

