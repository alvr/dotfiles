#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
	echo -e "\n${BLUE}================================${NC}"
	echo -e "${BLUE} $1${NC}"
	echo -e "${BLUE}================================${NC}"
}

print_step() {
	echo -e "\n${CYAN}[STEP]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
	exit 1
}

must_run() {
	local success_msg="${@: -2:1}"
	local error_msg="${@: -1}"
	local command=("${@:1:$#-2}")

	"${command[@]}"
	local status=$?

	if [ $status -eq 0 ]; then
		print_success "${success_msg}"
	else
		print_error "${error_msg}"
	fi

	return $status
}

run() {
	local success_msg="${@: -2:1}"
	local warning_msg="${@: -1}"
	local command=("${@:1:$#-2}")

	"${command[@]}" 2>/dev/null
	local status=$?

	if [ $status -eq 0 ]; then
		print_success "${success_msg}"
	else
		print_warning "${warning_msg}"
	fi

	return $status
}

clear

print_header "dotfiles Setup Script"
echo ""

echo -e "${PURPLE}This script will:${NC}"
echo "  1. Clear remainings"
echo "  2. Clone dotfiles repository"
echo "  3. Disk partitioning"
echo "  4. Generate necessary files"
echo "  5. Install NixOS configuration"
echo ""

print_warning "This script will perform system-level operations!"
print_warning "Make sure you understand what each step does before proceeding."

echo -e "${YELLOW}Press Enter to continue, or Ctrl+C to cancel...${NC}"
read -r </dev/tty || {
	print_error "Failed to read input. Ensure the script is run in an interactive terminal."
}

clear

# Step 1: Clear remainings
print_header "Step 1: Clear remainings"

print_step "Removing contents of /tmp folder..."
run rm -rf /tmp/* \
	"/tmp folder cleared successfully" \
	"Some files in /tmp could not be removed (this is often normal)"

print_step "Unmount /mnt..."
run umount -R /mnt \
	"/mnt unmounted successfully" \
	"/mnt is not mounted"

# Step 2: Clone dotfiles repository
print_header "Step 2: Clone dotfiles repository"

DOTFILES_DIR="/tmp/dotfiles"
print_step "Cloning dotfiles repository..."
must_run git clone https://git.alvr.dev/alvr/dotfiles.git ${DOTFILES_DIR} \
	"Dotfiles repository cloned successfully" \
	"Failed to clone dotfiles repository"

# Step 3: Disk partitioning
print_header "Step 3: Disk partitioning"

hosts=$(find ${DOTFILES_DIR}/hosts/* -maxdepth 1 -type d ! -name '.' -printf "%f," | sed 's/,$//')

echo ""
echo -n "Enter host name [${hosts[*]}]: "
read -r host </dev/tty || {
	print_error "Failed to read host name. Ensure the script is run in an interactive terminal."
}

if [ -z "${host}" ]; then
	print_error "Host name cannot be empty"
fi

print_step "Executing disko..."
must_run disko --yes-wipe-all-disks --mode destroy,format,mount ${DOTFILES_DIR}/hosts/${host}/disko.nix \
	"Disko executed successfully" \
	"Failed to run disko"

OLD_DOTFILES_DIR=${DOTFILES_DIR}
DOTFILES_DIR=/mnt/nix/persist/dotfiles

print_step "Moving dotfiles..."
must_run mv ${OLD_DOTFILES_DIR} ${DOTFILES_DIR} \
	"dotfiles moved from ${OLD_DOTFILES_DIR} to ${DOTFILES_DIR} successfully" \
	"Error moving dotfiles directory"

print_step "Creating persisting directory structure..."
must_run mkdir -pv /mnt/nix/{secret,persist/{etc/ssh,var/{lib,log}}} \
	"Persisting directory structure created successfully" \
	"Failed to create persisting directory structure"
#
print_step "Chmod /nix/secret with 700..."
run chmod 0700 /mnt/nix/secret \
	"/nix/secret successfully chmod-ed" \
	"/nix/secret failed to be chmod-ed"

# Step 4. Generate necessary files
print_header "Step 4: Generate necessary files"

AGE_KEY_FILE=/mnt/nix/secret/age-keys.txt
print_step "Generating age key..."
must_run age-keygen -o "${AGE_KEY_FILE}" \
	"Generated age key" \
	"Failed to generate age key"

print_step "Chmod age-keys.txt..."
run chmod 0400 ${AGE_KEY_FILE} \
	"Age key chmod-ed successfully" \
	"Failed to chmod age key"

SOPS_FILE=${DOTFILES_DIR}/.sops.yaml
SOPS_KEY_NAME="apeiron-new"
SOPS_AGE_KEY=$(cat ${AGE_KEY_FILE} | sed -n '2p' | awk '{print $NF}')

print_step "Setting new age key in sops"
awk -v key_name="$SOPS_KEY_NAME" -v age_key="$SOPS_AGE_KEY" '
BEGIN { in_keys = 0; keys_done = 0; in_age = 0 }

# Start of keys section
/^keys:/ { 
    print $0
    in_keys = 1
    next
}

# If we are in keys section and hit a line that starts with letter (not spaces/dashes)
in_keys && /^[a-zA-Z]/ && !keys_done {
    # Add our new key before this line
    print "  - &" key_name " " age_key
    keys_done = 1
    in_keys = 0
}

# If we are in keys section and see another key reference
in_keys && /^  - &/ {
    print $0
    next
}

# Look for the age section in creation_rules
/^[[:space:]]*- age:/ {
    print $0
    in_age = 1
    next
}

# If we are in age section and see the existing reference
in_age && /^[[:space:]]*- \*/ {
    print $0
    # Add our new key reference
    print "        - *" key_name
    in_age = 0
    next
}

# Print all other lines as-is
{ print $0 }
' ${SOPS_FILE} >${SOPS_FILE}.tmp
mv ${SOPS_FILE}.tmp ${SOPS_FILE}

print_step "Set age private keys"
echo "Enter age private keys, one by one (end with empty line):"
while IFS= read -r line </dev/tty; do
	[ -z "${line}" ] && break
	printf "%s\n" "${line}" >>"${AGE_KEY_FILE}"
done

print_step "Update sops encrypted files"
cd ${DOTFILES_DIR}
must_run env SOPS_AGE_KEY_FILE="${AGE_KEY_FILE}" sops updatekeys -y secrets/secrets.yaml \
	"Secret keys updated successfully" \
	"There was an error updating secret keys"
cd ${HOME}

# Step 5. Install NixOS configuration
print_header "Step 5: Install NixOS configuration"

print_step "Installing NixOS ${host} configuration..."
must_run nixos-install --no-root-passwd --root /mnt --flake ${DOTFILES_DIR}#$host --show-trace \
	"NixOS configuration for ${host} installed successfully" \
	"Failed to install NixOS configuration for ${host}"

print_header "Setup Complete!"
print_success "All steps completed successfully"
echo -e "${GREEN}Your system is now configured according to the '${host}' configuration.${NC}"
