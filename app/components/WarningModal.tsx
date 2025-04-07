import React from 'react';

type WarningModalProps = {
  isOpen: boolean;
  onClose: () => void;
};

export default function WarningModal({ isOpen, onClose }: WarningModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl [font-family:ProtoMono] text-[#0052FF]">Wallet Required</h2>
          <button 
            onClick={onClose}
            className="text-[#0052FF] hover:text-[#0033cc]"
          >
            ✕
          </button>
        </div>

        <div className="text-center [font-family:ProtoMono] text-[#0A0B0D] mb-4">
          <p>Please connect your wallet to participate in the pool.</p>
        </div>

        <div className="flex justify-center">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-[#0052FF] text-white rounded-full hover:bg-[#0033cc] transition-colors [font-family:ProtoMono]"
          >
            Got it
          </button>
        </div>
      </div>
    </div>
  );
} 