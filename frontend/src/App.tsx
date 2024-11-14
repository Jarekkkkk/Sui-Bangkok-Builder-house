import Panel from "@/components/Panel";
import { useCurrentAccount, useSuiClient } from "@mysten/dapp-kit";
import useGetAllBlobs from "./hooks/useGetAllBlobs";

export default function App() {
  const account = useCurrentAccount();
  const suiClient = useSuiClient();
  const blobs = useGetAllBlobs(suiClient, account?.address);
  return <Panel defaultLayout={undefined} navCollapsedSize={4} />;
}
