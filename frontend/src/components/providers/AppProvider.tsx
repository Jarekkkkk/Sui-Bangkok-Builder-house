import { createContext, PropsWithChildren } from "react";
import { registerStashedWallet } from "@mysten/zksend";

interface AppContext {}

const defaultContextValue: AppContext = {};

const AppContext = createContext<AppContext>(defaultContextValue);
export function AppContextProvider({ children }: PropsWithChildren) {
  registerStashedWallet("Sui-Sign");

  const contextValue = {};
  return (
    <AppContext.Provider value={contextValue}>{children}</AppContext.Provider>
  );
}
