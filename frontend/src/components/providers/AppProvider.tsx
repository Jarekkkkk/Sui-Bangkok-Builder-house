import {
  createContext,
  PropsWithChildren,
  useContext,
  useEffect,
  useState,
} from "react";
import { registerStashedWallet } from "@mysten/zksend";
import { GraphQLClient } from "graphql-request";
import {
  APP_ID,
  APP_SECRET,
  GMAIL_PROVIDER_ID,
  GRAPHQL_ENDPOINT,
} from "../../lib/constant";
import { ReclaimProofRequest } from "@reclaimprotocol/js-sdk";

interface AppContext {
  graphQLClient: GraphQLClient;
  reclaimRequest: null | ReclaimProofRequest;
}

const defaultContextValue: AppContext = {
  graphQLClient: new GraphQLClient(GRAPHQL_ENDPOINT),
  reclaimRequest: null,
};

const AppContext = createContext<AppContext>(defaultContextValue);

export function AppContextProvider({ children }: PropsWithChildren) {
  registerStashedWallet("Sui-Sign");

  const [reclaimRequest, setReclaimRequest] = useState<ReclaimProofRequest>();
  const graphQLClient = new GraphQLClient(GRAPHQL_ENDPOINT);
  const contextValue = {
    graphQLClient,
    reclaimRequest: reclaimRequest || null,
  };

  const setup = async () => {
    const reclaimProofRequest = await ReclaimProofRequest.init(
      APP_ID,
      APP_SECRET,
      GMAIL_PROVIDER_ID,
    );

    setReclaimRequest(reclaimProofRequest);
  };

  useEffect(() => {
    setup();
  }, []);
  return (
    <AppContext.Provider value={contextValue}>{children}</AppContext.Provider>
  );
}

export const useAppContext = () => useContext(AppContext);
