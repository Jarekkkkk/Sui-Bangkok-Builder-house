import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  ConnectModal,
  useCurrentAccount,
  useDisconnectWallet,
} from "@mysten/dapp-kit";
import { useState } from "react";

export function AccountSwitcher() {
  const { mutate: disconnect } = useDisconnectWallet();
  const currentAccount = useCurrentAccount();
  const [open, setOpen] = useState(false);

  const formatAddress =
    "0x" +
    currentAccount?.address.slice(0, 4) +
    "..." +
    currentAccount?.address.slice(-4);
  return currentAccount ? (
    <DropdownMenu>
      <DropdownMenuTrigger>{formatAddress}</DropdownMenuTrigger>
      <DropdownMenuContent>
        <DropdownMenuItem
          className="hover:bg-gray-400 hover:cursor-pointer"
          onClick={() => disconnect()}
        >
          Disconnect
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  ) : (
    <ConnectModal
      trigger={
        <button disabled={!!currentAccount}>
          {" "}
          {currentAccount ? "Connected" : "Connect"}
        </button>
      }
      open={open}
      onOpenChange={(isOpen) => setOpen(isOpen)}
    />
  );
}
