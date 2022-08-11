# Install homebrew if it's missing...
command -v brew >/dev/null 2>&1 || { echo >&2 "No hombrew detected, installing..."; \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
    echo -e "eval \"$(/opt/homebrew/bin/brew shellenv)\"" >> $HOME/.zshrc \
    eval "$(/opt/homebrew/bin/brew shellenv)"; }

# Setup prerequisites
brew install postgresql
brew install rbenv
rbenv install `cat .ruby-version`

# Setup the app
cp config/database.yml.example config/database.yml
bundle install
bundle exec rake db:create
bundle exec rake db:migrate

echo "If you would like to set this up to run at startup via launchd, run this next:"
echo -e "\n     sudo scripts/launchd/install_as_launch_daemon.sh\n"
