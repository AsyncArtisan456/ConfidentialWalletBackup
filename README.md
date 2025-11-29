````markdown
# 🧩 Confidential Wallet Backup — Zama FHEVM (Sepolia)

**ConfidentialWalletBackup** is a demonstration project for **encrypted key recovery backup** on the Sepolia test
network using the **Zama Fully Homomorphic Encryption Virtual Machine (FHEVM)** and **Relayer SDK**.

It enables users to upload an **encrypted share of their MPC secret** (a recovery fragment), manage access control, and
decrypt data in the browser through **EIP-712 signed user decryption** — without revealing any sensitive information.

---

## 🔐 Overview

- Each user stores their **encrypted recovery share** on-chain.
- The data is encrypted under the **Zama FHEVM global key** via the **Relayer SDK**.
- Access permissions are controlled via **FHE.allow() / FHE.allowTransient()**.
- Key recovery is initiated off-chain when an **admin or relayer** triggers `requestRecovery`.

---

## 🧱 Smart Contract: `ConfidentialWalletBackup.sol`

### 📜 Description

The contract provides secure storage, access control, and decryption of encrypted `euint256` values using the
**@fhevm/solidity** library.  
It supports public decryption, transient access, and secure revocation.

### ⚙️ Core Functions

| Function                                              | Description                                             |
| ----------------------------------------------------- | ------------------------------------------------------- |
| `uploadShare(externalEuint256 extShare, bytes proof)` | Uploads and stores a user’s encrypted share.            |
| `grantAccess(address user, address to)`               | Grants persistent decryption access to another address. |
| `grantTransientAccess(address user, address to)`      | Grants temporary (single-use) access.                   |
| `makeSharePublic(address user)`                       | Makes the share publicly decryptable.                   |
| `requestRecovery(address user)`                       | Initiates recovery (emits `RecoveryRequested` event).   |
| `getHandle(address user)`                             | Returns the encrypted handle (ciphertext ID).           |
| `revokeShare(address user)`                           | Revokes and zeroes the user’s share.                    |
| `storeSharePlain(address user, uint256 plain)`        | (Admin only) Stores a plaintext share directly.         |
| `version()`                                           | Returns the current contract version.                   |

### 🧩 Imports

```solidity
import { FHE, euint256, externalEuint256, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";
```
````

---

## 💻 Web Interface (`index.html`)

### 🧭 Features

The HTML interface provides a full client-side workflow:

1. Connect wallet (MetaMask)
2. Encrypt value using **Relayer SDK**
3. Upload encrypted share to the contract
4. Manage access control (grant / revoke / transient)
5. Trigger recovery and make shares public
6. Demonstrate private decryption via **EIP-712** signing

### 🧠 Dependencies

```js
import { BrowserProvider, Contract, getAddress } from "ethers@6.13.4";
import { initSDK, createInstance, SepoliaConfig, generateKeypair } from "relayer-sdk-js@0.2.0";
```

### 🌐 Relayer SDK Configuration

```js
const RELAYER_URL = "https://relayer.testnet.zama.cloud";
const relayer = await createInstance({
  ...SepoliaConfig,
  relayerUrl: RELAYER_URL,
  network: window.ethereum,
  debug: false,
});
```

---

## 📦 Project structure

```
root/
├─ contracts/
│  └─ ConfidentialWalletBackup.sol
├─ frontend/
│  └─ public/
│     └─ index.html   # Single-file app (UI + logic)
├─ server.js          # ESM Express static server
├─ package.json       # required Node packages file
├─ hardhat.config.ts  # main Hardhat config file
└─ .env               # optional HOST/PORT for the server
```

---

## 🧪 Quick Start

### 1️⃣ Deploy the Contract

```bash
forge create ConfidentialWalletBackup \
  --rpc-url https://sepolia.infura.io/v3/<YOUR_KEY> \
  --private-key <PRIVATE_KEY> \
  --constructor-args <RELAYER_ADDRESS>
```

### 3. Configure Frontend

In `index.html` update:

```js
  CONTRACT_ADDRESS: "<your deployed contract address>",
  RELAYER_URL: "https://relayer.testnet.zama.cloud",
  CHAIN_ID_HEX: "0xaa36a7", // Sepolia
```

### 2️⃣ Run the Frontend

Inside of the project root, run:

```bash
npm run start
```

## Open http://localhost:3001 in your browser.

---

## 🧰 Example Actions

### 🔒 Upload a Share

1. Enter `0xabc123...` in the input field
2. Click **Encrypt & Upload**
3. The console shows `Encrypted handle: 0x...` and transaction confirmation

### 🔓 Public Decrypt

1. Click **Make share public**
2. Then **Public decrypt**
3. The decrypted result (`0x...` or a number) appears in the console

### 🧾 User Decrypt (EIP-712)

1. Click **User decrypt (EIP-712)**
2. Approve the signature request in MetaMask
3. The console shows re-encrypted plaintext: `🧩 handle → value`

---

## 🪪 Contract Events

| Event                                              | Description                            |
| -------------------------------------------------- | -------------------------------------- |
| `ShareStored(address user, bytes32 handle)`        | A new encrypted share was uploaded.    |
| `AccessGranted(address user, address to)`          | Access granted for a specific address. |
| `TransientAccessGranted(address user, address to)` | Temporary (single-use) access granted. |
| `ShareRevoked(address user)`                       | User’s share was revoked.              |
| `ShareMadePublic(address user)`                    | Share is now publicly decryptable.     |
| `RecoveryRequested(address user, bytes32 handle)`  | Recovery process was requested.        |
| `RelayerSet(address by, address relayer)`          | Admin set a new relayer address.       |

---

## 🧠 Architecture

```
Browser (Relayer SDK)
   │
   ├─▶ Encrypts user input (FHE)
   │
   ├─▶ Sends proof + handle → Smart Contract
   │
   ├─▶ Manages access control via FHE.allow()
   │
   └─▶ Decrypts via relayer.publicDecrypt() or userDecrypt()
```

---

## ⚡️ Technical Details

- **Network:** Sepolia
- **Ethers:** v6.13.4
- **Relayer SDK:** v0.2.0
- **Relayer URL:** [https://relayer.testnet.zama.cloud](https://relayer.testnet.zama.cloud)
- **Contract version:** `ConfidentialWalletBackup/1.0.1`
- **FHE Primitive:** `euint256`
- **License:** MIT

---

## 📚 Documentation

- [Zama FHEVM Documentation](https://docs.zama.ai)
- [Relayer SDK Guides](https://docs.zama.org/protocol/relayer-sdk-guides/)
- [FHEVM Solidity Library](https://github.com/zama-ai/fhevm-solidity)
- [Ethers.js v6 Docs](https://docs.ethers.org/v6/)

---

> **Note:** This project runs entirely on Sepolia Testnet. For production, configure mainnet relayer endpoints and
> deploy with verified contracts.

## 🧾 License

MIT © 2025 — built with ❤️ using Zama FHEVM
