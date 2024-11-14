import { BLOB_STRUCT_TYPE } from "@/lib/constant";
import { useSuiClientQuery } from "@mysten/dapp-kit";
import { SuiClient } from "@mysten/sui/client";

export default function useGetAllBlobs(suiClient: SuiClient, account?: string) {
  const { data, isPending, isError, error, refetch } = useSuiClientQuery(
    "getOwnedObjects",
    {
      owner: account!,
      filter: {
        StructType: BLOB_STRUCT_TYPE,
      },
    },
    {
      gcTime: 10000,
      enabled: !!account,
    },
  );
  console.log("data", data);
}
