# git-shortcuts
# various git shortcuts / macros

function git-switch() {
    # saves local changes and switches to branch
    local branch_name="$1"
    git add -A
    git commit -m "WIP" --no-verify
    git pull origin "$branch_name"
    git checkout "$branch_name"
}

function git-rebase-to-master() {
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "Error: You have uncommitted changes. Please commit or stash them."
        return 1
    fi

    # Fetch the latest changes from the remote repository
    echo "Fetching latest updates from origin..."
    if ! git fetch origin master; then
        echo "Failed to fetch updates from origin."
        return 1
    fi
    
    # Rebase the current branch on top of the fetched master branch
    echo "Rebasing current branch onto master..."
    if ! git rebase origin/master; then
        echo "Rebase failed. Please resolve any conflicts manually."
        return 1
    fi
    
    echo "Rebase successful!"
}