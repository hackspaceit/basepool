"use client";

import {
  useMiniKit,
  useAddFrame,
  useOpenUrl,
} from "@coinbase/onchainkit/minikit";
import { Name, Identity } from "@coinbase/onchainkit/identity";
import { useCallback, useEffect, useMemo, useState } from "react";
import Snake from "./components/snake";
import { useAccount } from "wagmi";
import Check from "./svg/Check";

const SCHEMA_UID =
  "0x7889a09fb295b0a0c63a3d7903c4f00f7896cca4fa64d2c1313f8547390b7d39";

export default function App() {
  const { setFrameReady, isFrameReady, context } = useMiniKit();
  const [frameAdded, setFrameAdded] = useState(false);

  const addFrame = useAddFrame();
  const openUrl = useOpenUrl();
  const { address } = useAccount();

  useEffect(() => {
    if (!isFrameReady) {
      setFrameReady();
    }
  }, [setFrameReady, isFrameReady]);

  const handleAddFrame = useCallback(async () => {
    const frameAdded = await addFrame();
    setFrameAdded(Boolean(frameAdded));
  }, [addFrame, setFrameAdded]);

  const saveFrameButton = useMemo(() => {
    if (context && !context.client.added) {
      return (
        <button
          type="button"
          onClick={handleAddFrame}
          className="cursor-pointer bg-transparent font-semibold text-sm"
        >
          + SAVE FRAME
        </button>
      );
    }

    if (frameAdded) {
      return (
        <div className="flex items-center space-x-1 text-sm font-semibold animate-fade-out">
          <Check />
          <span>SAVED</span>
        </div>
      );
    }

    return null;
  }, [context, handleAddFrame, frameAdded]);

  return (
    <div className="flex flex-col h-[100dvh] w-[100dvw] overflow-hidden font-sans bg-[#E5E5E5] text-black items-center snake-dark relative">
      <div className="w-full max-w-[520px] px-2">
        <header className="mr-2 mt-1 flex justify-between">
          <div className="justify-start pl-1">
            {address ? (
              <Identity
                address={address}
                schemaId={SCHEMA_UID}
                className="!bg-inherit p-0 [&>div]:space-x-2"
              >
                <Name className="text-inherit">
                </Name>
              </Identity>
            ) : (
              <div className="pl-2 pt-1 text-gray-500 text-sm font-semibold">
                NOT CONNECTED
              </div>
            )}
          </div>
          <div className="pr-1 justify-end">{saveFrameButton}</div>
        </header>

        <main className="font-serif">
          {/* <BasePool /> */}
          <Snake />
        </main>

        <footer className="absolute bottom-4 flex flex-col items-center w-screen max-w-[520px] justify-center">
          <button
            type="button"
            className="px-2 py-1 flex justify-start rounded-2xl font-semibold opacity-40 border border-black text-xs"
            onClick={() => openUrl("https://base.org/builders/minikit")}
          >
            BUILT ON BASE WITH MINIKIT
          </button>
          <button
            type="button"
            className="mt-1 text-[10px] [font-family:ProtoMono] text-black opacity-40 cursor-pointer hover:opacity-70"
            onClick={() => openUrl("https://basescan.org/address/0xb40B5ef4c7cd998B5ef1F7aFB34E842F2Dac3A44")}
          >
            Smart Contract verified at BaseScan
          </button>
        </footer>
      </div>
    </div>
  );
}
