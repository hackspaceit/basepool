import React from 'react';
import { useContractRead } from 'wagmi';
import { CONTRACT_ADDRESS, CONTRACT_ABI, type PoolStatus } from '../lib/contract';
import { formatEther } from 'viem';

type PoolModalProps = {
  isOpen: boolean;
  onClose: () => void;
};

export default function PoolModal({ isOpen, onClose }: PoolModalProps) {
  const { data: poolStatus, isLoading } = useContractRead({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    functionName: 'getPoolStatus',
  }) as { data: PoolStatus | undefined; isLoading: boolean };

  if (!isOpen) return null;

  const currentBalance = poolStatus?.currentBalance ? Number(formatEther(poolStatus.currentBalance)) : 0;
  const threshold = poolStatus?.threshold ? Number(formatEther(poolStatus.threshold)) : 0.5;
  const progress = (currentBalance / threshold) * 100;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl [font-family:ProtoMono] text-[#0052FF]">Pool Status</h2>
          <button 
            onClick={onClose}
            className="text-[#0052FF] hover:text-[#0033cc]"
          >
            ✕
          </button>
        </div>

        {isLoading ? (
          <div className="text-center py-4 [font-family:ProtoMono] text-[#0052FF]">
            Loading pool status...
          </div>
        ) : (
          <>
            <div className="mb-4">
              <div className="flex justify-between text-sm [font-family:ProtoMono] mb-1">
                <span>Current Balance</span>
                <span>{currentBalance.toFixed(4)} ETH</span>
              </div>
              <div className="h-4 bg-gray-200 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-[#0052FF] transition-all duration-300"
                  style={{ width: `${progress}%` }}
                />
              </div>
              <div className="text-right text-xs [font-family:ProtoMono] mt-1">
                Target: {threshold} ETH
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4 [font-family:ProtoMono] text-sm">
              <div>
                <div className="text-gray-500">Pool ID</div>
                <div>{poolStatus?.poolId?.toString() || '0'}</div>
              </div>
              <div>
                <div className="text-gray-500">Total Numbers</div>
                <div>{poolStatus?.totalNumbers?.toString() || '0'}</div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
} 