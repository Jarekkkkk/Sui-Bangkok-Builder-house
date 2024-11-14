import { useMutation } from "@tanstack/react-query";
import { gql, GraphQLClient } from "graphql-request";

interface Input {
  bytes: string;
  signature: string;
  address: string;
}
export default function useVerifyZKLogin(client: GraphQLClient) {
  return useMutation({
    mutationFn: async ({ bytes, signature, address }: Input) => {
      const query = gql`
        query VerifyZKLoginSig(
          $bytes: Base64!
          $signature: Base64!
          $address: SuiAddress!
        ) {
          verifyZkloginSignature(
            bytes: $bytes
            signature: $signature
            intentScope: PERSONAL_MESSAGE
            author: $address
          ) {
            success
          }
        }
      `;

      try {
        const {
          verifyZkloginSignature: { success },
        } = await client.request<{
          verifyZkloginSignature: { success: boolean };
        }>(query, {
          bytes,
          signature,
          address,
        });

        return success;
      } catch (error: any) {
        throw new Error(error);
      }
    },
    onSuccess: () => console.log("success"),
    onError: (error: Error) => console.error(error),
  });
}
