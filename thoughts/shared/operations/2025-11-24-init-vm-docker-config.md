---
status: completed
created_at: 2025-11-24
requester: user
files_edited:
  - .bashrc
rationale: Update init-vm to copy docker config for seamless authentication
supporting_docs: []
follow_up_actions: []
---

# Update init-vm to copy Docker config

## Summary

Updated the `init_vm` function in `.bashrc` to copy `/mnt/user/appdata/docker/config.json` to `/home/coder/.docker/config.json`.

## Technical Reasoning

The user requested that the Docker configuration be automatically set up when initializing the VM. This ensures that the user is authenticated with the Docker registry without manual intervention.

## Impact Assessment

- **User Experience**: Simplifies setup by automating Docker config copying.
- **Backward Compatibility**: Fully compatible; adds a step to the existing function.
- **Security**: Copies sensitive config (auth tokens), but destination is in the user's home directory, which is standard.

## Validation

- Verified source file existence.
- Verified destination directory existence.
- Added command to `init_vm` function.
