# 🌐 Private Geo-Age Access — Zama FHEVM DApp

> **Fully Homomorphic Encrypted geolocation + age gate on Ethereum Sepolia Testnet**  
> Combines encrypted latitude/longitude and age checks to grant access **without ever revealing the user’s private
> data**.

---

## 🧩 Overview

`PrivateGeoAgeAccess` is a **confidential smart contract** built on [Zama’s FHEVM](https://docs.zama.ai/protocol) that
enables access control based on a user’s **encrypted age** and **encrypted geolocation**.

- 🧭 Checks if the user is **inside a geofenced area** (latitude/longitude).
- 🎂 Verifies that the user’s **age ≥ minimum threshold**.
- 🔒 Returns an **encrypted boolean** (`ebool`) — publicly decryptable only if access is granted.
- 🧠 All comparisons and logic are performed **directly on ciphertexts**, preserving privacy.

---

````markdown
## ⚙️ Smart Contract

**File:** `contracts/PrivateGeoAgeAccess.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { FHE, ebool, euint16, euint64, externalEuint16, externalEuint64 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";
```
````

### Core Functions

| Function                                                                                  | Description                                                                 |
| ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `setGeofence(int64 latMin, int64 latMax, int64 lonMin, int64 lonMax)`                     | Updates the allowed coordinate boundaries.                                  |
| `setMinAge(uint16 age)`                                                                   | Sets minimum allowed user age (1–150).                                      |
| `checkAccess(externalEuint64 lat, externalEuint64 lon, externalEuint16 age, bytes proof)` | Combines encrypted geo & age to produce an encrypted `ebool` access result. |

### Events

| Event                                               | Purpose                                                                               |
| --------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `GeoUpdated(...)`                                   | Emitted when the admin updates geofence limits.                                       |
| `MinAgeUpdated(uint16)`                             | Emitted when the minimal allowed age changes.                                         |
| `AccessChecked(address user, bytes32 resultHandle)` | Fired after each access verification; the result handle can be decrypted via relayer. |

---

## 🌍 Frontend (Relayer SDK v0.2.0)

**File:** `frontend/index.html`

A standalone frontend that connects via MetaMask to Sepolia and interacts with Zama’s Relayer:

- Uses [`@zama-fhe/relayer-sdk`](https://docs.zama.ai/protocol/relayer-sdk-guides/) for encryption/decryption.
- Integrates [`ethers.js v6`](https://docs.ethers.org/v6/) for contract interaction.
- Supports both **admin mode** (for the owner) and **user mode** (for encrypted verification).

---

## 🚀 Quick Start

### 1. Prerequisites

- Node ≥ 18
- MetaMask connected to **Sepolia**
- Contract deployed with Zama’s Solidity libraries (`@fhevm/solidity`)
- Access to Zama Relayer endpoint (default: `https://relayer.testnet.zama.cloud`)

### 2. Deploy the Contract

```bash
# Example deployment via Hardhat
npx hardhat run scripts/deploy.js --network sepolia
```

Constructor arguments:

| Parameter                                  | Type     | Description                           |
| ------------------------------------------ | -------- | ------------------------------------- |
| `scale`                                    | `uint64` | Precision multiplier (e.g. 1 000 000) |
| `_latMin`, `_latMax`, `_lonMin`, `_lonMax` | `int64`  | Geofence bounds × scale               |
| `_minAge`                                  | `uint16` | Minimal allowed age                   |

Example:

```js
constructor(1_000_000, 35000000, 60000000, -10000000, 30000000, 18);
```

---

### 3. Configure Frontend

In `index.html` update:

```js
const CONFIG = {
  CONTRACT: "<your deployed contract address>",
  RELAYER_URL: "https://relayer.testnet.zama.cloud",
  CHAIN_ID_HEX: "0xaa36a7", // Sepolia
};
```

Then open the file locally or serve it with a simple dev server:

```bash
npm run start
```

## Open http://localhost:3001 in your browser.

## 🧠 How It Works

1. The frontend uses Zama’s **Relayer SDK** to encrypt user inputs:
   - Latitude → `euint64`
   - Longitude → `euint64`
   - Age → `euint16`

2. These encrypted values are submitted to `checkAccess()` with a **proof** from the relayer.

3. The contract performs:
   - FHE comparisons (`FHE.ge`, `FHE.le`) on ciphertexts.
   - Combines results with `FHE.and` to produce an `ebool`.

4. The resulting `ebool` is:
   - Made **publicly decryptable** using `FHE.makePubliclyDecryptable`.
   - Also allowed for the user via `FHE.allow`.

5. The frontend retrieves the handle from `AccessChecked` and calls:

   ```js
   const result = await relayer.publicDecrypt([handle]);
   ```

6. The decrypted value (`1` or `0`) determines whether access is granted.

---

## 📦 Project structure

```
root/
├─ contracts/
│  └─ PrivateGeoAgeAccess.sol
├─ frontend/
│  └─ public/
│     └─ index.html   # Single-file app (UI + logic)
├─ server.js          # ESM Express static server
├─ package.json       # required Node packages file
├─ hardhat.config.ts  # main Hardhat config file
└─ .env               # optional HOST/PORT for the server
```

## 🛠️ Admin Panel

The **Admin Controls** section allows the owner to:

- `🔄 Load Current` — read on-chain limits.
- `🌍 Update Geofence` — update allowed region.
- `🎂 Update Min Age` — adjust minimum age requirement.

All calls require ownership and are sent via MetaMask.

---

## 🧪 Example Workflow

1. **User connects wallet** → Relayer + FHEVM initialized.
2. **User enters latitude, longitude, and age**.
3. SDK encrypts data → sends to `checkAccess`.
4. Contract evaluates encrypted logic.
5. Result decrypted by `publicDecrypt` → UI shows ✅ Access Granted / ⛔ Denied.

---

## 🧱 Technologies

| Component         | Stack                              |
| ----------------- | ---------------------------------- |
| Blockchain        | Ethereum Sepolia (EVM)             |
| Privacy Layer     | Zama FHEVM                         |
| SDK               | `@zama-fhe/relayer-sdk@0.2.0`      |
| Contract Language | Solidity ^0.8.25                   |
| Frontend          | HTML + JS (ES Modules)             |
| Wallet            | MetaMask / EIP-1193 provider       |
| Encryption        | Fully Homomorphic Encryption (FHE) |

---

## 🧾 License

MIT © 2025 — built with ❤️ using Zama FHEVM

---

> **Note:** This project runs entirely on Sepolia Testnet. For production, configure mainnet relayer endpoints and
> deploy with verified contracts.
