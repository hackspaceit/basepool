// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * BasePool 0.2
 * miniapp de Farcaster que usa Pyth Network para generación de numeros aleatorios
 * basado en ApeBomb de 0xQuit
 * https://x.com/0xQuit
 * https://apescan.io/address/0xC1932844eDcc3193ae2622089c4B57ae5F023D7f
 */

import {IEntropy} from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Pool {
    uint256 nextNumberToAssign;
    mapping(uint256 explicitNumber => address participant) explicitNumbers;
}

contract BasePool is IEntropyConsumer, Ownable {
    error InvalidAmount();
    error TransferFailed();
    error TargetExceeded();
    error EmergencyWithdrawNotYetRequested();
    error EmergencyWithdrawNotYetAvailable();

    event Participation(
        uint256 indexed poolId, 
        address indexed participant, 
        uint256 startNumber, 
        uint256 endNumber
    );
    event ConquerorSelected(
        uint256 indexed poolId, 
        address indexed conqueror, 
        uint256 amount
    );
    event EmergencyWithdrawRequested(uint256 emergencyWithdrawTimestamp);

    /* testnet
    *IEntropy public constant ENTROPY = IEntropy(0x41c9e39574F40Ad34c79f1C99B66A45eFB830d4c);
    *address public constant PROVIDER = 0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344;
    */

    // mainnet
    IEntropy public constant ENTROPY = IEntropy(0x6E7D74FA7d5c90FEF9F0512987605a6d546181Bb);
    address public constant PROVIDER = 0x52DeaA1c84233F7bb8C8A45baeDE41091c616506;
    

    mapping(uint256 poolId => Pool pool) public pools;
    mapping(uint256 poolId => uint256) public conqueredNumbers;

    uint256 public currentPoolId;
    uint256 public emergencyWithdrawTimestamp;
    address private immutable FEE_WALLET;

    uint256 private constant ENTRY_COST = 0.0005 ether;
    uint256 private constant POOL_TARGET = 0.5 ether; // 1000 números * 0.0005 ETH
    uint256 public constant FEE_RATE = 50; // 5%

    constructor() Ownable(msg.sender) {
        FEE_WALLET = msg.sender;
    }

    // asignamos un número al participar
    receive() external payable {
        _enter();
    }

    /**
     * función de retiro de fondos en caso de que pyth deje de funcionar
     * tiempo de espera = 1 año a partir de la fecha de la solicitud
     * si el pool se cierra antes de que se cumpla el tiempo de espera, la solicitud se resetea
     */
    function requestEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawTimestamp = block.timestamp + 365 days;

        emit EmergencyWithdrawRequested(emergencyWithdrawTimestamp);
    }

    function fulfillEmergencyWithdraw() external onlyOwner {
        if (emergencyWithdrawTimestamp == 0) revert EmergencyWithdrawNotYetRequested();
        if (block.timestamp < emergencyWithdrawTimestamp) revert EmergencyWithdrawNotYetAvailable();

        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function entropyCallback(uint64, /* sequenceNumber */ address, /* provider */ bytes32 randomNumber)
        internal
        override
    {
        if (address(this).balance < POOL_TARGET) return;

        uint256 random = uint256(randomNumber);
        uint256 selectedNumber = random % pools[currentPoolId].nextNumberToAssign;

        // guardamos el número conquistado
        conqueredNumbers[currentPoolId] = selectedNumber;

        address participant = _findParticipant(selectedNumber);
        if (participant == address(0)) return;

        // calculamos montos a enviar
        uint256 totalAmount = address(this).balance;
        uint256 commission = (totalAmount * FEE_RATE) / 1000;
        uint256 prize = totalAmount - commission;

        // transferimos balance al número seleccionado
        (bool successConqueror,) = participant.call{value: prize}("");
        if (!successConqueror) revert TransferFailed();

        // transferimos al owner del pool
        (bool successFee,) = FEE_WALLET.call{value: commission}("");
        if (!successFee) revert TransferFailed();

        emit ConquerorSelected(currentPoolId, participant, prize);

        emergencyWithdrawTimestamp = 0;

        unchecked {
            ++currentPoolId;
        }
    }

    function _enter() internal {
        // validamos que el monto sea divisible por ENTRY_COST
        if (msg.value == 0 || msg.value % ENTRY_COST != 0) revert InvalidAmount();

        uint256 numNumbers = msg.value / ENTRY_COST;

        _assignNumber(numNumbers);

        // pagamos las comisiones y solicitamos un numero aleatorio de entropy si llegamos al target
        if (address(this).balance >= POOL_TARGET) {
            bytes32 pseudoRandomNumber =
                keccak256(abi.encode(block.timestamp, block.number, msg.sender, address(this).balance));

            uint128 requestFee = ENTROPY.getFee(PROVIDER);

            ENTROPY.requestWithCallback{value: requestFee}(PROVIDER, pseudoRandomNumber);
        }
    }

    function getEntropy() internal pure override returns (address) {
        return address(ENTROPY);
    }

    function _assignNumber(uint256 numNumbers) internal {
        uint256 startNumber = pools[currentPoolId].nextNumberToAssign;

        // asignamos cada numero individualmente
        for (uint256 i = 0; i < numNumbers; i++) {
            pools[currentPoolId].explicitNumbers[startNumber + i] = msg.sender;
        }

        uint256 nextNumberToAssign = startNumber + numNumbers;
        pools[currentPoolId].nextNumberToAssign = nextNumberToAssign;

        emit Participation(currentPoolId, msg.sender, startNumber, nextNumberToAssign - 1);
    }

    function _findParticipant(uint256 number) internal view returns (address) {
        for (uint256 i = number; i >= 0; --i) {
            address participant = pools[currentPoolId].explicitNumbers[i];
            if (participant != address(0)) {
                return participant;
            }

            if (i == 0) {
                return address(0);
            }
        }

        return address(0);
    }

    // consulta para el estado actual del pool -> visible en basescan
    function getPoolStatus() external view returns (
        uint256 poolId,
        uint256 totalNumbers,
        uint256 currentBalance,
        uint256 threshold
    ) {
        return (
            currentPoolId,
            pools[currentPoolId].nextNumberToAssign,
            address(this).balance,
            POOL_TARGET
        );
    }

    // consulta de números asignados por dirección -> visible en basescan
    function getParticipantNumbers(address participant) external view returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[](pools[currentPoolId].nextNumberToAssign);
        uint256 count = 0;

        for (uint256 i = 0; i < pools[currentPoolId].nextNumberToAssign; i++) {
            if (pools[currentPoolId].explicitNumbers[i] == participant) {
                numbers[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = numbers[i];
        }

        return result;
    }

    // consulta de números por dirección -> visible en basescan
    function getParticipantNumberCount(address participant) external view returns (uint256) {
        uint256 count = 0;
        Pool storage pool = pools[currentPoolId];
        
        for (uint256 i = 0; i < pool.nextNumberToAssign; i++) {
            if (pool.explicitNumbers[i] == participant) {
                count++;
            }
        }
        
        return count;
    }

    // consulta de número conquistado de un pool específico -> visible en basescan
    function getConqueredNumber(uint256 poolId) external view returns (uint256) {
        return conqueredNumbers[poolId];
    }

    // consulta de todos los números conquistados -> visible en basescan
    function getAllConqueredNumbers() external view returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[](currentPoolId);
        for (uint256 i = 0; i < currentPoolId; i++) {
            numbers[i] = conqueredNumbers[i];
        }
        return numbers;
    }
}
/**
 * BasePool 0.2
 * miniapp de Farcaster que usa Pyth Network para generación de numeros aleatorios
 * basado en ApeBomb de 0xQuit
 * https://x.com/0xQuit
 * https://apescan.io/address/0xC1932844eDcc3193ae2622089c4B57ae5F023D7f
 */