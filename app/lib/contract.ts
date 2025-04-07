import { Address } from 'viem';

export const CONTRACT_ADDRESS = '0xF9f40e4a0d85A5F6aE758E4C40623A62EFC943f3' as Address;

export const CONTRACT_ABI = [
  {
    stateMutability: "payable",
    type: "receive"
  },
  {
    inputs: [],
    name: "getPoolStatus",
    outputs: [
      { name: "poolId", type: "uint256" },
      { name: "totalNumbers", type: "uint256" },
      { name: "currentBalance", type: "uint256" },
      { name: "threshold", type: "uint256" }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ name: "participant", type: "address" }],
    name: "getParticipantNumbers",
    outputs: [{ name: "", type: "uint256[]" }],
    stateMutability: "view",
    type: "function"
  }
] as const;

export type PoolStatus = {
  poolId: bigint;
  totalNumbers: bigint;
  currentBalance: bigint;
  threshold: bigint;
}; 