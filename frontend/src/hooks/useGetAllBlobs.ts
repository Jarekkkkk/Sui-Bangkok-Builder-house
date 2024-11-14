import { BLOB_STRUCT_TYPE } from "@/lib/constant";
import { useSuiClientQuery } from "@mysten/dapp-kit";

export default function useGetAllBlobs(account?: string) {
  return useSuiClientQuery(
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
}
