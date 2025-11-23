// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/* Zama FHEVM - official imports only */
import { FHE, euint256, externalEuint256, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { ZamaEthereumConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract ConfidentialWalletBackup is ZamaEthereumConfig {
    address public admin;
    address public relayer;
    modifier onlyAdmin() { require(msg.sender == admin, "not admin"); _; }

    mapping(address => euint256) private _share;
    mapping(address => bool)     private _hasShare;

    event ShareStored(address indexed user, bytes32 handle);
    event ShareRevoked(address indexed user);
    event AccessGranted(address indexed user, address indexed to);
    event TransientAccessGranted(address indexed user, address indexed to);
    event RecoveryRequested(address indexed user, bytes32 handle);
    event ShareMadePublic(address indexed user);
    event RelayerSet(address indexed by, address indexed relayer);

    constructor(address _relayer) {
        admin = msg.sender;
        relayer = _relayer;
    }

    function setRelayer(address _relayer) external onlyAdmin {
        require(_relayer != address(0), "zero relayer");
        relayer = _relayer;
        emit RelayerSet(msg.sender, _relayer);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "zero admin");
        admin = newAdmin;
    }

    function uploadShare(externalEuint256 extShare, bytes calldata proof) external {
        euint256 shareHandle = FHE.fromExternal(extShare, proof);
        _share[msg.sender] = shareHandle;
        _hasShare[msg.sender] = true;

        FHE.allow(shareHandle, msg.sender);
        FHE.allowThis(shareHandle);

        emit ShareStored(msg.sender, FHE.toBytes32(shareHandle));
    }

    function grantAccess(address user, address to) external {
        require(to != address(0), "bad addr");
        require(_hasShare[user], "no share");
        require(msg.sender == user || msg.sender == admin, "not authorized");

        euint256 s = _share[user];
        FHE.allow(s, to);
        emit AccessGranted(user, to);
    }

    function grantTransientAccess(address user, address to) external {
        require(to != address(0), "bad addr");
        require(_hasShare[user], "no share");
        require(msg.sender == user || msg.sender == admin, "not authorized");

        euint256 s = _share[user];
        FHE.allowTransient(s, to);
        emit TransientAccessGranted(user, to);
    }

    function makeSharePublic(address user) external {
        require(_hasShare[user], "no share");
        require(msg.sender == user || msg.sender == admin, "not authorized");

        euint256 s = _share[user];
        FHE.makePubliclyDecryptable(s);
        emit ShareMadePublic(user);
    }

    function requestRecovery(address user) external returns (bytes32) {
        require(_hasShare[user], "no share");
        require(msg.sender == admin || msg.sender == relayer, "not authorized");

        euint256 s = _share[user];
        bytes32 h = FHE.toBytes32(s);
        emit RecoveryRequested(user, h);
        return h;
    }

    function getHandle(address user) external view returns (bytes32) {
        require(_hasShare[user], "no share");
        require(msg.sender == user || msg.sender == admin || msg.sender == relayer, "not authorized");
        return FHE.toBytes32(_share[user]);
    }

    function revokeShare(address user) external {
        require(_hasShare[user], "no share");
        require(msg.sender == user || msg.sender == admin, "not authorized");

        _share[user] = FHE.asEuint256(0); // ✅ fixed
        _hasShare[user] = false;

        emit ShareRevoked(user);
    }

    function storeSharePlain(address user, uint256 plain) external onlyAdmin {
        euint256 h = FHE.asEuint256(plain);
        _share[user] = h;
        _hasShare[user] = true;
        FHE.allowThis(h);
        FHE.allow(h, user);
        emit ShareStored(user, FHE.toBytes32(h));
    }

    function version() external pure returns (string memory) {
        return "ConfidentialWalletBackup/1.0.1";
    }
}
