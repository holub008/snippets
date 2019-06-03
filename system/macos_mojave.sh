# here's a record of how I set up my macbook running MacOS Mojave
# if you read, you'll notice it's primaryily R/python/java/js setup
# these commands have some interactive aspects, so should probably be run via line by line copy/paste

hostname kholub-mac
# setting up ssh keys, including adding to ssh-agent to avoid repeated password entry after initial login
mkdir ~/.ssh
ssh-keygen -t rsa -b 4096 -C "karljholub@gmail.com"
eval "$(ssh-agent -s)"
echo "Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
ssh-add -K ~/.ssh/id_rsa

echo "alias ls='ls -al'" >> ~/.bash_profile

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install r
## note that there are the following caveats:
#==> Caveats
#==> gettext
#gettext is keg-only, which means it was not symlinked into /usr/local,
#because macOS provides the BSD gettext library & some software gets confused if both are in the library path.
#If you need to have gettext first in your PATH run:
#  echo 'export PATH="/usr/local/opt/gettext/bin:$PATH"' >> ~/.bash_profile
#For compilers to find gettext you may need to set:
#  export LDFLAGS="-L/usr/local/opt/gettext/lib"
#  export CPPFLAGS="-I/usr/local/opt/gettext/include"
#==> openblas
#openblas is keg-only, which means it was not symlinked into /usr/local,
#because macOS provides BLAS and LAPACK in the Accelerate framework.

#For compilers to find openblas you may need to set:
#  export LDFLAGS="-L/usr/local/opt/openblas/lib"
#  export CPPFLAGS="-I/usr/local/opt/openblas/include"
#==> readline
#readline is keg-only, which means it was not symlinked into /usr/local,
#because macOS provides the BSD libedit library, which shadows libreadline.
#In order to prevent conflicts when programs look for libreadline we are
#defaulting this GNU Readline installation to keg-only.
#For compilers to find readline you may need to set:
#  export LDFLAGS="-L/usr/local/opt/readline/lib"
#  export CPPFLAGS="-I/usr/local/opt/readline/include"


brew cask install sublime-text
brew install python
echo "alias python='python3'" >> ~/.bash_profile
brew install pipenv
echo "export PIPENV_VENV_IN_PROJECT=1" >> ~/.bash_profile
brew install openssl
brew install postgresql
# postgresql had the following caveats:
==> icu4c
icu4c is keg-only, which means it was not symlinked into /usr/local,
#because macOS provides libicucore.dylib (but nothing else).
#If you need to have icu4c first in your PATH run:
#  echo 'export PATH="/usr/local/opt/icu4c/bin:$PATH"' >> ~/.bash_profile
#  echo 'export PATH="/usr/local/opt/icu4c/sbin:$PATH"' >> ~/.bash_profile
#For compilers to find icu4c you may need to set:
#  export LDFLAGS="-L/usr/local/opt/icu4c/lib"
#  export CPPFLAGS="-I/usr/local/opt/icu4c/include"
#==> postgresql
#To migrate existing data from a previous major version of PostgreSQL run:
#  brew postgresql-upgrade-database
#To have launchd start postgresql now and restart at login:
#  brew services start postgresql
#Or, if you don't want/need a background service you can just run:
#  pg_ctl -D /usr/local/var/postgres start

touch ~/.pgpass
# manually enter credentials here :)
sudo chmod 600 ~/.pgpass

brew install node
brew cask install java
brew install maven
brew install pkg-config
softwareupdate --install -a
# sets up headers that some R (and possibly python) packages will need
sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
# may need a reboot after this

# Rstudio installed from binary here: https://www.rstudio.com/products/rstudio/download/#download
# pycharm installed from binary here: https://www.jetbrains.com/pycharm/download/#section=mac
# launcher script is at: /usr/local/bin/charm
# intellij installed from binary here: https://www.jetbrains.com/idea/download/#section=mac
# launcher script is at: /usr/local/bin/idea

# a bunch of globally installed R packages that are useful for EDA & modeling 
# may run into issues with tidyverse installation if lib-xml / xcode is out of date or otherwise funky
R -e "install.packages(c('tidyverse', 'tidyr', 'fuzzyjoin', 'ggplot2', 'devtools', 'xgboost', 'glmnet', 'keras', 'RPostgreSQL'), repos='http://cran.us.r-project.org')"

# a few (public) personal projects
git clone git@github.com:holub008/nymph.git
git clone git@github.com:holub008/birkielo.git
git clone git@github.com:holub008/xrf.git
git clone git@github.com:holub008/xgboost_jvm_scoring.git
git clone git@github.com:holub008/snippets.git

(cd birkielo && npm install --prefix server) && (cd birkielo && npm install --prefix client)
# pycharm is such a beautiful tool that it will actually find the virtualenv created here and set it as the project interpretter by default
(cd birkielo/offline && pipenv install)
# these will be installed globally on the system
R -e "devtools::install_git('https://github.com/holub008/xrf')" && R -e "devtools::install_git('https://github.com/holub008/nymph')"

echo "alias pip='pip3'" >> ~/.bash_profile
