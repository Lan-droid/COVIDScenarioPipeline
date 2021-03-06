@ECHO FALSE

:: sclone
:: function to clone a git repository with submodules
:: and track the submodule branch specified in .gitmodules
:git-sclone
git clone --recurse-submodules %~1
git submodule update --remote --recursive
git submodule foreach -q --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)'
echo "repository successfully cloned; remember to commit any changes to submodule"
EXIT /B 0

:: spull
:: function to pull a git repository with submodules
:: pull the most recent commit of the specified submodule branch
:: and track that branch
:git-spull
git pull
git submodule sync --recursive
git submodule update --init --remote --recursive
git submodule foreach -q --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)'
echo "repository successfully updated; remember to commit any changes to submodule"
EXIT /B 0

:: spush
:: function to push changes in a repository with submodules
:git-spush
git push --recurse-submodules=on-demand
EXIT /B 0

:: sdiff
:: function to get a list of changes for main repository and all submodules
:git-sdiff
git diff && git submodule foreach 'git diff'
EXIT /B 0

EXIT /B 0