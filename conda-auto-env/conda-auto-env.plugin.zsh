# conda-auto-env 
# Standalone script to auto-activate conda environments based on .conda-version file

function conda_auto_env() {
  local current_dir conda_env version_file

  current_dir="$PWD"
  version_file=".conda-version"

  while [ "$current_dir" != "/" ]; do
    if [ -e "$current_dir/$version_file" ]; then
      # If .conda-version file is found, read the first line and activate the environment
      conda_env=$(head -n 1 "$current_dir/$version_file")
      if [ "$conda_env" != "$CONDA_DEFAULT_ENV" ]; then
        echo "Activating conda environment: $conda_env"
        conda activate "$conda_env"
      fi
      return 0
    fi
    current_dir=$(dirname "$current_dir")
  done

  # Deactivate if there's no .conda-version file and a conda environment is active
  if [ -n "$CONDA_DEFAULT_ENV" ]; then
    echo "Deactivating conda environment: $CONDA_DEFAULT_ENV"
    conda deactivate
  fi
}

function cd() {
  builtin cd "$@"
  conda_auto_env
}

# Run conda_auto_env when the shell starts
conda_auto_env