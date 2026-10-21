# Local cleanup — 21 October 2026

The user requested removal of Cinder-only dependencies, storage and software after GitHub publication, while retaining tools installed for other purposes. The source checkout and its Git history are retained. The GitHub repository must remain public and **unarchived**.

Cleanup is pending verified remote source and mobile release assets. Candidates are the local Godot executable/download, imported caches, generated exports, test captures, private coordination/scratch storage, retired managed worktrees, Cinder-named test saves, Cinder-specific Xcode DerivedData, the matching mobile templates and the Godot Tools extension installed for this project. Unique unpublished source is retained before removing scratch/worktree storage. Shared Xcode, Android SDK, JDK, VS Code, nvm/Node and signing credentials are preserved. Existing unrelated simulator versions and user data are preserved.

The newly downloaded iOS26.5/23F73 simulator is separately identifiable and removable with Apple's supported runtime manager; no system developer directory or mounted volume is manually deleted. Any cleanup that cannot be completed safely is recorded here rather than implied complete.
