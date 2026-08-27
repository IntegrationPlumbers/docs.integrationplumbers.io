---
title: Troubleshooting
nav_order: 25
---

# Troubleshooting

Ordered by how often each one actually happens.

**In this page:** Target is Down · Target is Up but data is missing · Certificate problems · Jobs fail · Import and deploy problems · What to send when you report something

## Target is Down {#target-down}

**Straight after being added.** The credentials were passed inline with `add_target`, which is silently ignored by this plug-in — it uses a monitoring credential set applied *after* creation. Re-apply them and the target comes Up on its next collection. See [Credentials](credentials.html#applying).

**After a plug-in upgrade, on a target that verifies certificates.** A deploy cycle can reset truststore credentials to placeholder values. Re-apply them. Targets not verifying certificates are unaffected. See [TLS connections](tls.html#after-upgrade).

**Intermittently.** Check the agent can still reach the instance on its port, and that the monitoring login has not expired or been locked out. A password policy that expires the monitoring login will take the target Down on the next collection with no other symptom.

## Target is Up but data is missing {#missing-data}

**Everything is thin and the target is new.** Expected for up to 24 hours. Configuration, per-database space and the database inventory collect daily. The Overview page compensates with a one-off live read for the slowest two; other surfaces fill in on schedule.

**One page is empty and the rest are fine.** Usually a grant. Metrics whose permission is missing return no rows rather than failing, so the effect is a blank page rather than an error. Check the monitoring login against [Credentials](credentials.html#grants).

**A table shows fewer rows than you expect.** Some collections are deliberately filtered — index fragmentation only covers indexes above a size worth acting on, so small indexes are absent by design.

**Two families report less on SQL Server 2016 and 2017.** TempDB contention collects, but allocation-page and metadata-page waiter counts read zero because those releases do not expose them. Not a fault.

## Certificate problems {#certificates}

A target set to verify the certificate goes Down with a certificate-path error. In order of likelihood: an incomplete chain in the truststore, a name mismatch between the certificate and how the target connects, truststore credentials that are wrong or absent, or an expired certificate.

Quickest diagnostic: set the target to encrypted-without-verification. If it comes Up, the network and login are fine and the problem is certificate validation. [TLS connections](tls.html#failures) has the detail.

## Jobs fail {#jobs}

**On a target that monitors perfectly well.** Jobs use a separate credential path from monitoring. A host credential must be set as a preferred credential on the SQL Server target type, and the truststore credential set must resolve on every target — using the literal `none` where no truststore is in use. See [Jobs](jobs.html#prerequisites).

**Unresolved credential reference.** The truststore credential set is empty on that target. Populate it, with `none` values if the target does not use a truststore.

**It works from the command line but not the console.** A job submitted with credentials bound explicitly bypasses preferred credentials. The console relies on the preferred credential, so this pattern means the preferred credential was never set.

**Permission denied.** Jobs need grants beyond the monitoring login's read-only set — see the table in [Jobs](jobs.html#grants). Delete backup needs `sysadmin` by SQL Server's own design and is meant to be run with override credentials.

## Import and deploy problems {#import-deploy}

**Incompatible version on import.** The archive was built for a different Enterprise Manager release. Use the build matching yours — see [Install and upgrade](install-and-upgrade.html#which-build).

**Entity already exists.** That version is already in the Software Library. Enterprise Manager will not import the same version twice, even if the file has changed. Ask for a build with the version incremented.

## What to send when you report something {#reporting}

The more of this you include, the faster it resolves:

- Enterprise Manager release, and the plug-in version from the target's page
- SQL Server version and edition, and the host operating system
- Whether the agent is local to the database host or remote
- The exact command or console action, and the exact error text
- For a monitoring problem: which page or metric, and whether the target is Up
- For a job: whether it was submitted from the console or the command line

For a target that has been up less than a day, say so — it changes what an empty page means.
