#!/bin/bash

# Extract dependencies and devDependencies from package.json
deps=$(jq -r '.dependencies | keys | join(" ")' package.json)
devDeps=$(jq -r '.devDependencies | keys | join(" ")' package.json)

# Prompt the user for the package manager
read -p "Enter package manager (yarn/npm/pnpm): " pkg_manager

# Determine install commands
case "$pkg_manager" in
    yarn)
        install_cmd="yarn add"
        dev_install_cmd="yarn add --dev"
        ;;
    npm)
        install_cmd="npm install"
        dev_install_cmd="npm install --save-dev"
        ;;
    pnpm)
        install_cmd="pnpm add"
        dev_install_cmd="pnpm add --save-dev"
        ;;
    *)
        echo "Invalid package manager. Please use yarn, npm, or pnpm."
        exit 1
        ;;
esac

# Generate the install script
cat <<EOF > install_deps.sh
#!/bin/bash

# Install dependencies
$install_cmd $deps

# Install dev dependencies
$dev_install_cmd $devDeps
EOF

# Make the script executable
chmod +x install_deps.sh

echo "Generated install_deps.sh. Run it with ./install_deps.sh"
