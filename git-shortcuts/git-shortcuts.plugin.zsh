# git-shortcuts
# various git shortcuts / macros

function check_uncommitted_changes() {
    if ! git diff-index --quiet HEAD --; then
        echo "Error: You have uncommitted changes. Please commit or stash them."
        return 1
    fi
    return 0
}

function git-switch-branch() {
    # Intentionally forces a WIP commit and skips hooks to quickly save state
    # and switch branches. Use with caution as it bypasses normal commit checks.
    if [ $# -eq 0 ]; then
        echo "Usage: git-switch-branch <branch_name>"
        return 1
    fi

    local branch_name="$1"

    # Check if the branch exists locally or remotely
    if ! git show-ref --verify --quiet refs/heads/"$branch_name" && \
       ! git show-ref --verify --quiet refs/remotes/origin/"$branch_name"; then
        echo "Error: Branch $branch_name does not exist locally or remotely"
        return 1
    fi

    git add -A
    git commit -m "WIP" --no-verify
    if ! git pull origin "$branch_name"; then
        echo "Error: Failed to pull from origin/$branch_name"
        return 1
    fi
    if ! git checkout "$branch_name"; then
        echo "Error: Failed to checkout $branch_name"
        return 1
    fi
    echo "Successfully switched to branch $branch_name"
}

function git-rebase-to-master() {
    local main_branch="master"
    local stash_created=false  # Initialize at start
    local force_mode=false

    # Handle --force flag
    if [[ "$1" == "--force" ]]; then
        force_mode=true
    fi

    # Try to detect if the repository uses 'main' instead of 'master'
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        main_branch="main"
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        if [[ "$force_mode" == true ]]; then
            echo "Force mode: Automatically stashing changes..."
            if ! git stash push -m "Automated stash before rebase to $main_branch"; then
                echo "Error: Failed to stash changes"
                return 1
            fi
            stash_created=true
        else
            echo "You have uncommitted changes. What would you like to do?"
            echo "1) Stash changes, rebase, and reapply stash"
            echo "2) Abort rebase"
            read -r "choice?Enter your choice (1 or 2): "
            
            case $choice in
                1)
                    echo "Stashing changes..."
                    if ! git stash push -m "Automated stash before rebase to $main_branch"; then
                        echo "Error: Failed to stash changes"
                        return 1
                    fi
                    stash_created=true
                    ;;
                2)
                    echo "Rebase aborted"
                    return 0
                    ;;
                *)
                    echo "Invalid choice. Rebase aborted"
                    return 1
                    ;;
            esac
        fi
    fi

    # Fetch the latest changes from the remote repository
    echo "Fetching latest updates from origin..."
    if ! git fetch origin "$main_branch"; then
        # If we stashed changes, pop them back before returning
        if [ "$stash_created" = true ]; then
            echo "Reapplying stashed changes..."
            git stash pop
        fi
        echo "Error: Failed to fetch from origin/$main_branch"
        return 1
    fi
    
    # Rebase the current branch on top of the fetched master/main branch
    echo "Rebasing current branch onto $main_branch..."
    if ! git rebase "origin/$main_branch"; then
        if [ "$stash_created" = true ]; then
            echo "Rebase conflicts detected and you have stashed changes."
            echo "Please resolve the conflicts and run 'git rebase --continue'"
            echo "After the rebase is complete, run 'git stash pop' to reapply your changes"
            echo "Your changes are safely stored in the stash."
        else
            echo "Rebase failed. Please resolve conflicts and run 'git rebase --continue'"
        fi
        return 1
    fi
    
    # If we stashed changes, reapply them
    if [ "$stash_created" = true ]; then
        echo "Reapplying stashed changes..."
        if ! git stash pop; then
            echo "Error: Conflicts while reapplying stashed changes."
            echo "Your changes are still in the stash."
            echo "Resolve conflicts manually and then run 'git stash pop'"
            return 1
        fi
    fi
    
    echo "Rebase successful!"
}

function git-push-new-branch() {
    # Get the current branch name
    local branch_name="$(git branch --show-current)"
    if [ -z "$branch_name" ]; then
        echo "Error: Not currently on any branch"
        return 1
    fi

    # Check for uncommitted changes
    if ! check_uncommitted_changes; then
        return 1
    fi

    # Push the current branch to the remote and set upstream tracking
    echo "Pushing new branch '$branch_name' to remote..."
    if ! git push -u origin "$branch_name"; then
        echo "Error: Failed to push branch $branch_name to origin"
        return 1
    fi

    echo "Push successful and upstream tracking set!"
}

function git-checkout-upstream() {
    if [ $# -eq 0 ]; then
        echo "Usage: git-checkout-upstream <branch_name>"
        return 1
    fi

    local branch_name="$1"
    local remote_name="origin"

    # Check for uncommitted changes
    if ! check_uncommitted_changes; then
        return 1
    fi

    # Check if branch already exists locally
    if git show-ref --verify --quiet refs/heads/"$branch_name"; then
        echo "Error: Branch '$branch_name' already exists locally"
        return 1
    fi

    # Fetch only the specified branch from the remote
    echo "Fetching branch '$branch_name' from $remote_name..."
    if ! git fetch "$remote_name" "$branch_name"; then
        echo "Error: Failed to fetch branch $branch_name from $remote_name"
        return 1
    fi

    # Check if the branch exists on the remote
    if git ls-remote --exit-code --heads "$remote_name" "$branch_name" >/dev/null 2>&1; then
        # Create a new local branch tracking the remote branch
        echo "Checking out branch '$branch_name'..."
        if ! git checkout -b "$branch_name" "$remote_name/$branch_name"; then
            echo "Error: Failed to checkout branch $branch_name"
            return 1
        fi
        echo "Branch '$branch_name' checked out successfully!"
    else
        echo "Error: Branch '$branch_name' does not exist on remote '$remote_name'"
        return 1
    fi
}

function git-change-commit-msg() {
    # Amends the last commit message
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "Error: No commits exist yet"
        return 1
    fi
    
    if ! git commit --amend; then
        echo "Error: Failed to amend commit message"
        return 1
    fi
}

function git-cleanup() {
    local main_branch="master"
    
    # Check which main branch exists (master or main)
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        main_branch="main"
    fi
    
    echo "Starting cleanup process..."
    
    # Prune remote-tracking branches
    echo "Pruning remote branches..."
    git remote prune origin
    
    # Remove already merged local branches
    echo "Removing merged local branches..."
    # The grep pattern now handles both main and master
    git branch --merged "$main_branch" | grep -v "^\*\|master\|main" | xargs -r git branch -d
    
    # Optimize repository
    echo "Running garbage collection..."
    git gc
    
    echo "Cleanup complete!"
}