# Downloads and user snapshots

The protected download repository, explicit saved-file inclusion and user-created snapshot repository were not implemented. Keep encrypted, profile-scoped metadata distinct from external downloads. Metadata deletion does not authorize file deletion. Snapshots have manual retention, no private entries and explicit deletion. Internal recovery artifacts remain distinct. Backup includes approved metadata, excludes downloaded files by default, and requires user selection and conflict handling to restore external files.

[Backup scope](backup-recovery.md) · [Owner requirements](../M1/m1-developer-specification.md)
