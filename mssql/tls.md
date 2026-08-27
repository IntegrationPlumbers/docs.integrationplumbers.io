---
title: TLS connections
nav_order: 9
---

# TLS connections

The plug-in connects with encryption by default. What you choose per target is whether the server's certificate is also **verified**.

**In this page:** The two modes · Choosing a mode · Setting up verification · When verification fails · After a plug-in upgrade

## The two modes {#modes}

| Mode | Encrypted | Certificate verified | Needs a truststore |
| :--- | :--- | :--- | :--- |
| Required | Yes | No | No |
| Verify | Yes | Yes | Yes |

**Required** encrypts the connection but accepts whatever certificate the server presents, including a self-signed one. It protects the traffic; it does not prove you are talking to the right server.

**Verify** validates the certificate chain against a truststore you provide, and checks the name. This is the stronger setting and the one to use where the instance holds anything sensitive.

## Choosing a mode {#choosing}

Set it when you add the target. It can be changed later on the target's monitoring configuration.

Most estates start on Required, because it works immediately, and move individual targets to Verify as certificates get put in place. There is no functional difference in what the plug-in collects — every metric behaves identically under both.

## Setting up verification {#setup}

Verification needs three things on the **agent** host, not the database host:

1. A truststore containing the certificate chain that signed the SQL Server certificate.
2. The truststore type.
3. The truststore password.

These are held as a credential set on the target, separate from the login credentials. Supply them when you set the target to Verify.

The name the plug-in expects in the certificate is configurable, which matters when you connect by address but the certificate carries a host name.

## When verification fails {#failures}

A target set to Verify whose certificate does not validate goes Down with a certificate-path error. In order of likelihood:

- **The chain is incomplete.** The truststore has the server certificate but not the issuing authority, or is missing an intermediate. Import the full chain.
- **The name does not match.** The certificate carries a host name and the target connects by address, or vice versa. Set the expected name on the target.
- **The truststore credentials are wrong or absent.** See below — this is common right after an upgrade.
- **The certificate has expired.** The plug-in will not accept an expired certificate in Verify mode.

Setting the target back to Required is a legitimate way to confirm the problem is certificate validation rather than connectivity: if it comes Up on Required and Down on Verify, the network and login are fine.

## After a plug-in upgrade {#after-upgrade}

A deploy cycle can reset a target's truststore credentials to placeholder values. The target then goes Down with a certificate-path error even though nothing about the certificate changed.

If a verifying target fails immediately after a plug-in upgrade, re-apply its truststore credentials before investigating anything else. Targets on Required are unaffected, because they have no truststore to lose.
