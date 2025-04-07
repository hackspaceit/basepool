"use client";

import React, {
  useState,
} from "react";
import { useNotification } from "@coinbase/onchainkit/minikit";
import {
  ConnectWallet,
  ConnectWalletText,
  Wallet,
  WalletDropdown,
  WalletDropdownDisconnect,
} from "@coinbase/onchainkit/wallet";
import {
  Name,
  Identity,
  EthBalance,
  Address,
  Avatar,
} from "@coinbase/onchainkit/identity";
import { useAccount, usePublicClient, useWalletClient } from "wagmi";
import { parseEther } from "viem";
import "./basepool.css";
import { CONTRACT_ADDRESS } from "../lib/contract";
import PoolModal from './PoolModal';
import WarningModal from './WarningModal';

type ControlButtonProps = {
  className?: string;
  children?: React.ReactNode;
  onClick: () => void;
};

function ControlButton({ children, onClick, className }: ControlButtonProps) {
  const [isPressed, setIsPressed] = useState(false);

  return (
    <button
      type="button"
      className={`w-12 h-12 bg-[#0052FF] rounded-full cursor-pointer select-none
        transition-all duration-150 border-[1px] border-[#0052FF] ${className}
        ${
          isPressed
            ? "translate-y-1 [box-shadow:0_0px_0_0_#002299,0_0px_0_0_#0033cc33] border-b-[0px]"
            : "[box-shadow:0_5px_0_0_#002299,0_8px_0_0_#0033cc33]"
        }`}
      onPointerDown={() => setIsPressed(true)}
      onPointerUp={() => setIsPressed(false)}
      onPointerLeave={() => setIsPressed(false)}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

function WalletControl() {
  return (
    <Wallet className="[&>div:nth-child(2)]:!opacity-20 md:[&>div:nth-child(2)]:!opacity-100">
      <ConnectWallet className="w-12 h-12 bg-[#0052FF] rounded-full hover:bg-[#0052FF] focus:bg-[#0052FF] cursor-pointer select-none transition-all duration-150 border-[1px] border-[#0052FF] min-w-12 [box-shadow:0_5px_0_0_#002299,0_8px_0_0_#0033cc33]">
        <ConnectWalletText>{""}</ConnectWalletText>
      </ConnectWallet>
      <WalletDropdown>
        <Identity className="px-4 pt-3 pb-2 [font-family:ProtoMono]" hasCopyAddressOnClick>
          <Avatar />
          <Name />
          <Address />
          <EthBalance />
        </Identity>
        <WalletDropdownDisconnect />
      </WalletDropdown>
    </Wallet>
  );
}

type PillButtonProps = {
  numbers: string;
  eth: string;
  onClick: () => void;
};

function PillButton({ numbers, eth, onClick }: PillButtonProps) {
  return (
    <button
      onClick={onClick}
      className="w-full px-4 py-2 border border-[#0052FF] rounded-full bg-white hover:bg-gray-50 transition-colors text-center group [font-family:ProtoMono]"
    >
      <div className="text-[#0052FF] text-base leading-tight">{numbers}</div>
      <div className="text-[#0A0B0D] text-xs leading-tight">{eth}</div>
    </button>
  );
}

export default function BasePool() {
  const { address } = useAccount();
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isWarningOpen, setIsWarningOpen] = useState(false);
  const notification = useNotification();

  const handleTransaction = async (amount: string) => {
    if (!walletClient || !address || !publicClient) {
      setIsWarningOpen(true);
      return;
    }
    
    try {
      const hash = await walletClient.sendTransaction({
        to: CONTRACT_ADDRESS,
        value: parseEther(amount),
      });

      const receipt = await publicClient.waitForTransactionReceipt({ hash });
      console.log('Transaction successful:', receipt);

      // Share to Farcaster
      await notification({
        title: "BasePool Participation",
        body: `I just participated in BasePool and sent ${amount} ETH to join the pool! 🎲\n\nhttps://basepool.miniapps.zone`
      });

    } catch (error) {
      console.error('Transaction failed:', error);
    }
  };

  return (
    <div className="mt-1 mx-2 w-full h-full">
      <div className="relative origin-top-left w-[96%] h-[70vh] bg-[#0052FF] p-[10px] rounded-lg">
        <div className="absolute top-[10px] left-[10px] right-[10px] bottom-[10px] w-[calc(100%-20px)] h-[calc(100%-20px)] bg-white rounded-lg z-4 px-3 pt-2 pb-3">
          <div className="text-center mb-3">
            <h1 className="text-[#0052FF] text-4xl mb-1 [font-family:ProtoMono] leading-tight">
              BasePool
            </h1>
            <h2 className="text-[#0052FF] text-xl [font-family:ProtoMono] leading-tight">
              A provable fair Pool on Base
            </h2>
          </div>

          <div className="text-[#0A0B0D] text-base [font-family:ProtoMono] leading-snug mb-4">
            <p className="flex items-start mb-2">
              <span className="mr-2">🔵</span>
              <span>For each 0.0005 ETH sent to the contract get assigned a number.</span>
            </p>
            <p className="flex items-start mb-2">
              <span className="mr-2">🔵</span>
              <span>When the contract balance hits 0.5 ETH the next tx triggers a random draw using Pyth Network</span>
            </p>
            <p className="flex items-start mb-2">
              <span className="mr-2">🔵</span>
              <span>Selected number receives the balance on the contract.</span>
            </p>
            <p className="flex items-start">
              <span className="mr-2">🔵</span>
              <span>A new pool starts!</span>
            </p>
          </div>

          <div className="grid grid-cols-2 gap-2 max-w-xl mx-auto px-2">
            <PillButton 
              numbers="1 Number"
              eth="0.0005 ETH"
              onClick={() => handleTransaction("0.0005")}
            />
            <PillButton 
              numbers="3 Numbers"
              eth="0.00015 ETH"
              onClick={() => handleTransaction("0.00015")}
            />
            <PillButton 
              numbers="5 Numbers"
              eth="0.0025 ETH"
              onClick={() => handleTransaction("0.0025")}
            />
            <PillButton 
              numbers="10 Numbers"
              eth="0.005 ETH"
              onClick={() => handleTransaction("0.005")}
            />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-x-4 mt-6">
        <div className="flex justify-center">
          <img 
            src="/baseBlue.png" 
            alt="Base Logo" 
            className="w-14 h-14si"
          />
        </div>
        <div className="flex justify-center">
          <ControlButton onClick={() => setIsModalOpen(true)} className="block" />
        </div>
        <div className="flex justify-center">
          <WalletControl />
        </div>

        <div className="flex justify-center pt-4">
          {/* Primera columna vacía */}
        </div>
        <div className="flex justify-center pt-4">
          <span className="text-sm [font-family:ProtoMono] text-[#0052FF]">Pool Status</span>
        </div>
        <div className="flex justify-center pt-4">
          <span className="text-sm [font-family:ProtoMono] text-[#0052FF]">
            {address ? "Logout" : "Login"}
          </span>
        </div>
      </div>

      <PoolModal 
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
      />
      <WarningModal
        isOpen={isWarningOpen}
        onClose={() => setIsWarningOpen(false)}
      />
    </div>
  );
}
