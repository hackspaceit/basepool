// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IEntropy} from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 /**
 * BasePool
 * Miniapp de Farcaster que usa Pyth Network para generación de numeros aleatorios
 * basado en ApeBomb de 0xQuit
 * https://x.com/0xQuit
 * https://apescan.io/address/0xC1932844eDcc3193ae2622089c4B57ae5F023D7f
 */

struct Pool {
    uint256 nextEntryToAssign;
    mapping(uint256 explicitEntry => address entrant) explicitEntries;
}

contract BasePool is IEntropyConsumer, Ownable {
    error InvalidAmount();
    error TransferFailed();

    event Participation(
        uint256 indexed poolId,
        address indexed participant,
        uint256 amount  
    );
    event Distribution(
        uint256 indexed poolId,
        address indexed selectedNumber,
        uint256 amount
    );

    /* testnet
    *IEntropy public constant ENTROPY = IEntropy(0x41c9e39574F40Ad34c79f1C99B66A45eFB830d4c);
    *address public constant PROVIDER = 0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344;
    */

    // mainnet
    IEntropy public constant ENTROPY = IEntropy(0x6E7D74FA7d5c90FEF9F0512987605a6d546181Bb);
    address public constant PROVIDER = 0x52DeaA1c84233F7bb8C8A45baeDE41091c616506;

    mapping(uint256 poolId => Pool pool) public pools;

    uint256 public currentPoolId;
    uint256 public emergencyRequestTimestamp;
    bool public emergencyRequested;

    // características del pool
    // cambiar valores de acuerdo a objetivos
    uint256 private constant ENTRY_COST = 0.0005 ether;
    uint256 private constant POOL_TARGET = 0.5 ether;
    uint256 public constant FEE_RATE = 50;
    uint256 private constant EMERGENCY_WAIT_TIME = 365 days; // 1 año de espera
    address private immutable FEE_WALLET;

    constructor() Ownable(msg.sender) {
        currentPoolId = 0;
        FEE_WALLET = msg.sender;
        emergencyRequested = false;
    }

    receive() external payable {
        _enter();
    }

    /**
     * callback de Pyth Network que procesa el número aleatorio
     * se ejecuta cuando:
     * 1. el contrato alcanza el target
     * 2. se recibe el número aleatorio de Pyth
     * al ejecutar, se distribuye el pool: 96.5% / 3.5%
     */
    function entropyCallback(
        uint64,
        address,
        bytes32 randomNumber
    ) internal override {
        if (address(this).balance < POOL_TARGET) return;

        uint256 random = uint256(randomNumber);
        uint256 entryNumber = random % pools[currentPoolId].nextEntryToAssign;

        // busca la dirección seleccionada
        address selectedNumber = _findEntrant(entryNumber);
        if (selectedNumber == address(0)) return;

        // calcula montos a enviar
        uint256 totalAmount = address(this).balance;
        uint256 commission = (totalAmount * FEE_RATE) / 1000;
        uint256 prize = totalAmount - commission;

        // transfiere fondos a dirección seleccionada
        (bool successSelected,) = selectedNumber.call{value: prize}("");
        if (!successSelected) revert TransferFailed();

        // transfiere comisión
        (bool successFee,) = FEE_WALLET.call{value: commission}("");
        if (!successFee) revert TransferFailed();

        emit Distribution(currentPoolId, selectedNumber, prize);

        // si todo sale bien, iniciamos la siguiente pool
        unchecked {
            ++currentPoolId;
        }
    }

    /**
     * función principal para procesar entradas, valida que:
     * 1. monto a recibir sea múltiplo de 0.0005 eth
     * 2. asigna números según el monto enviado
     * si llegamos al target, solicita número aleatorio
     */
    function _enter() internal {
        // validamos que el monto sea múltiplo de la entrada
        if (msg.value == 0 || msg.value % ENTRY_COST != 0) 
            revert InvalidAmount();

        uint256 numEntries = msg.value / ENTRY_COST;
        _assignEntrant(numEntries);

        // solicitamos un número aleatorio al alcanzar el pool target
        if (address(this).balance >= POOL_TARGET) {
            bytes32 pseudoRandomNumber = keccak256(
                abi.encode(
                    block.timestamp,
                    block.number,
                    msg.sender,
                    address(this).balance
                )
            );

            uint128 requestFee = ENTROPY.getFee(PROVIDER);
            ENTROPY.requestWithCallback{value: requestFee}(PROVIDER, pseudoRandomNumber);
        }
    }

    /**
     * optimizamos consumo de gas:
     * 1. guardamos una referencia cada 100 números
     * 2. números intermedios se calculan al buscar ganador
     */
    function _assignEntrant(uint256 numEntries) internal {
        uint256 entryNumber = pools[currentPoolId].nextEntryToAssign;
        uint256 totalExplicitEntriesToSet = numEntries / 100 + 1;

        for (uint256 i = 0; i < totalExplicitEntriesToSet; ++i) {
            uint256 explicitEntryNumber;
            unchecked {
                explicitEntryNumber = entryNumber + i * 100;
            }
            pools[currentPoolId].explicitEntries[explicitEntryNumber] = msg.sender;
        }

        uint256 nextEntryToAssign;
        unchecked {
            nextEntryToAssign = entryNumber + numEntries;
        }

        pools[currentPoolId].nextEntryToAssign = nextEntryToAssign;

        emit Participation(
            currentPoolId,
            msg.sender,
            msg.value
        );
    }

    function _findEntrant(uint256 entryNumber) internal view returns (address) {
        for (uint256 i = entryNumber; i >= 0; --i) {
            address entrant = pools[currentPoolId].explicitEntries[i];
            if (entrant != address(0)) {
                return entrant;
            }
            if (i == 0) break;
        }
        return address(0);
    }

    function getEntropy() internal pure override returns (address) {
        return address(ENTROPY);
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
            pools[currentPoolId].nextEntryToAssign,
            address(this).balance,
            POOL_TARGET
        );
    }

    // consulta de número asignados por dirección -> visible en basescan
    function getParticipantNumbers(address participant) external view returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[](pools[currentPoolId].nextEntryToAssign);
        uint256 count = 0;

        for (uint256 i = 0; i < pools[currentPoolId].nextEntryToAssign; i++) {
            if (pools[currentPoolId].explicitEntries[i] == participant) {
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

    // consulta de entradas por dirección -> visible en basescan
    function getParticipantEntryCount(address participant) external view returns (uint256) {
        uint256 count = 0;
        Pool storage pool = pools[currentPoolId];
        
        for (uint256 i = 0; i < pool.nextEntryToAssign; i++) {
            if (pool.explicitEntries[i] == participant) {
                count++;
            }
        }
        
        return count;
    }

    /**
     * función para solicitar retiro de emergencia
     * en caso que pyth network deje de funcionar
     * una vez solicitada, hay que esperar 1 año para poder ejecutarla
     */
    function requestEmergencyWithdraw() external onlyOwner {
        require(!emergencyRequested, "Ya se ha solicitado retiro de emergencia");
        emergencyRequested = true;
        emergencyRequestTimestamp = block.timestamp;
    }

    function executeEmergencyWithdraw() external onlyOwner {
        require(emergencyRequested, "No se ha solicitado retiro de emergencia");
        require(
            block.timestamp >= emergencyRequestTimestamp + EMERGENCY_WAIT_TIME,
            "No ha pasado el tiempo de espera"
        );

        uint256 balance = address(this).balance;
        (bool success,) = owner().call{value: balance}("");
        require(success, "Transferencia fallida");
    }

    /**
     * BasePool
     * Miniapp de Farcaster que usa Pyth Network para generación de numeros aleatorios
     * basado en ApeBomb de 0xQuit
     * https://x.com/0xQuit
     * https://apescan.io/address/0xC1932844eDcc3193ae2622089c4B57ae5F023D7f
     */
} 