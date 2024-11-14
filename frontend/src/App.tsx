import Panel from "@/components/Panel";
import { useCurrentAccount } from "@mysten/dapp-kit";
import useGetAllBlobs from "./hooks/useGetAllBlobs";

export default function App() {
  const account = useCurrentAccount();
  const blobs = useGetAllBlobs(account?.address);
  console.log("blobs", blobs);
  return <Panel defaultLayout={undefined} navCollapsedSize={4} />;
}
