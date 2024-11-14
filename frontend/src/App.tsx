import {
  ConnectButton,
  useCurrentAccount,
  useCurrentWallet,
  useSignPersonalMessage,
  useSignTransaction,
  useSuiClient,
} from "@mysten/dapp-kit";
import { Box, Button, Container, Flex, Heading } from "@radix-ui/themes";
import { AsyncCache, Transaction } from "@mysten/sui/transactions";
import {
  getSentTransactionsWithLinks,
  ZkSendLinkBuilder,
} from "@mysten/zksend";
import { SUI_TYPE_ARG } from "@mysten/sui/utils";
import { ChangeEvent, useEffect, useState } from "react";
import { WALRUS_AGGREGATOR, WALRUS_PUBLISHER } from "./lib/constant";
import { fileToBlob, streamToBlob } from "./lib/util";
import { parseZkLoginSignature } from "@mysten/sui/zklogin";
import { gql, GraphQLClient } from "graphql-request";
import useVerifyZKLogin from "./components/hooks/useVerifyZKLogin";
import { useAppContext } from "./components/providers/AppProvider";
import QRCode from "react-qr-code";

function App() {
  const { graphQLClient, reclaimRequest } = useAppContext();
  const suiClient = useSuiClient();
  const { mutateAsync: signTransaction } = useSignTransaction();
  const account = useCurrentAccount();
  const wallet = useCurrentWallet();
  const { mutate: signPersonalMessage } = useSignPersonalMessage();
  const [file, setFile] = useState<File>();
  const [imageSrc, setImageSrc] = useState<string>();
  const [reclaimUrl, setReclaimUrl] = useState<string>();
  const handleFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (files?.[0]) {
      setFile(files[0]);
    }
  };

  const handleOnClick = async () => {
    if (!account) return;
    try {
      const { data, hasNextPage, nextCursor } =
        await getSentTransactionsWithLinks({
          address: account.address,
          network: "testnet",
        });

      const tx = new Transaction();
      const link = new ZkSendLinkBuilder({
        sender: account.address,
        network: "testnet",
      });

      const payCoin = tx.splitCoins(tx.gas, [10 ** 6]);

      link.addClaimableObjectRef(payCoin, `0x2::coin::Coin<${SUI_TYPE_ARG}>`);
      link.createSendTransaction({
        transaction: tx,
      });

      console.log("link", link.getLink());

      const { bytes, signature } = await signTransaction({
        transaction: tx,
        chain: "sui:testnet",
      });

      const executeResult = await suiClient.executeTransactionBlock({
        transactionBlock: bytes,
        signature,
        options: {
          showRawEffects: true,
        },
      });

      console.log("res", executeResult);
    } catch (error) {
      console.error(error);
    }
  };

  const handleUpload = async () => {
    if (!file) return;
    console.log("file", file);
    try {
      const blob = (await fileToBlob(file)) as Blob;
      const response = await fetch(`${WALRUS_PUBLISHER}/v1/store`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/octet-stream",
          "Content-Disposition": `attachment; filename="${file.name}"`,
        },
        body: blob,
      });

      console.log("response", response);
    } catch (error) {
      console.error(error);
    }
  };

  const handleViewFile = async () => {
    try {
      const response = await fetch(
        `${WALRUS_AGGREGATOR}/v1/Nrf8zNPXB9FhquvEAGEZzi0u28s6rTnRBdmnfh7S1lw`,
      );

      console.log("response", response.body);
      const blob = await streamToBlob(response.body);
      if (!blob) return null;
      const objectURL = URL.createObjectURL(blob);
      console.log("imageUrl", objectURL);
      setImageSrc(objectURL);
    } catch (error) {
      console.error(error);
    }
  };

  const handleSign = async () => {
    console.log("wallet", wallet.currentWallet);
    const message = new TextEncoder().encode("foo");
    await signPersonalMessage(
      { message },
      {
        onSuccess: async (sig) => {
          console.log("sig", sig);
        },
      },
    );
  };

  const handleRequest = async () => {
    if (!reclaimRequest) return;
    const requestUrl = await reclaimRequest.getRequestUrl();
    setReclaimUrl(requestUrl);

    await reclaimRequest.startSession({
      onSuccess: (proofs) => {
        console.log("Verification success", proofs);
      },
      onError: (error) => {
        console.error("Verification failed", error);
      },
    });
  };

  const { mutateAsync: verifySig } = useVerifyZKLogin(graphQLClient);

  const handleVerify = async () => {
    const res = await verifySig({
      bytes: "Zm9v",
      signature:
        "BQNMMTk4MzAxMzg0NzY2ODMxNTI4MDQxODU5OTkyNTIzNzQwODE1NDM4Njg5MDc2ODA1ODg1NDg3Mjc1ODIxNzY3Njk1ODEyMTU3MTEzN00xMDU4ODY5NDA2Njc0NTczODQzOTQwNjg4NTUxMzY0MDIwMTA0ODU0NDk5OTIzMDYxMzk3MTYyMTMwNjQ4MTQ4MDMzNTAxNTIzNTk4MQExAwJNMTYxODEzMTUyODM4ODI4MTQ5NTY1NTU4NTk3OTk2NDMyNjc1Mzc2MTM0NzMxNDczMDQzNzMyMzM3MzMxNzUyMzYwODQ3MDI2MTg1OTFMNDAwMDY5MTUxMjEyNTg4MDQ3MjE2MTQzODg4NTczODQ1MjI1MjQyNDk4MjgxODMxNTIzOTUyMjAxNTUyMTg0NjkzMTE5OTM4MDA0MAJNMTQzMjY4NTMxMDE0NDAxMTA3MzM3NzU4NTQzMDQ1MzQ0ODE1NTI4Njc4OTM2MjI2ODAxNzIyMzY3MjkyNzE3NzI0NDc4MDk1NDQyNDVNMTQwOTI1NjI1ODc0MzY4OTAxNTk0ODUwMzM1MzYyODUyNDU3ODE2MzcyNzY5NDA2ODU0OTUyNjgzMDI2MTE4MzkwNzA4ODg1OTQ5MzcCATEBMANMNjY1Mjk2NTY3ODU5NzA5MzI1MTMwMTgyMzEwNDE3MjY5MTE3MjU2NTYyNzI1Nzg0MDI2NzIzODk3OTM3MDMxNjY5Mjc3NTgwOTIxMEw4ODEzMTc0NDc4NjQzMzY1MDk2NDI0NzM4OTM3ODgyNzk4NDk4NjgwNTY2Njc5ODUwMTA5NTM5MDcyMzMyOTY1NTM2MzY3MjY2MzY0ATExeUpwYzNNaU9pSm9kSFJ3Y3pvdkwyRmpZMjkxYm5SekxtZHZiMmRzWlM1amIyMGlMQwFmZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklqRmtZekJtTVRjeVpUaGtObVZtTXpneVpEWmtNMkV5TXpGbU5tTXhPVGRrWkRZNFkyVTFaV1lpTENKMGVYQWlPaUpLVjFRaWZRTTIwOTUzNTg4NjQwNzAxNzE5ODYyMjA3MjM2NTUzOTgxMTk2MzU0MzY0Mjg1MDc5NDE1Njk1OTYxNTkwNzg5ODE5OTczOTg2NDQ3Njc3RgIAAAAAAABhAMCoW7pf29Y/N5i/7BEV2m79+/2UEQP4zLjyzbH+z8NfKyqpbUpxbIbSAR0wO9GMwggEAHy0MUiRmXHZAWc7fgPr7teN2O5eCe21LpLTgQ4IpdmhxBbj2p18jaU+hSP46w==",
      address:
        "0xb36c184f4c8570d7f9dd6c35d88359ee4e3f2f0765ec950f30571f2a5a610f6c",
    });

    console.log("res", res);
  };

  return (
    <>
      <Flex
        position="sticky"
        px="4"
        py="2"
        justify="between"
        style={{
          borderBottom: "1px solid var(--gray-a2)",
        }}
      >
        <Box>
          <Heading>dApp Starter Template</Heading>
        </Box>

        <Box>
          <ConnectButton />
        </Box>
      </Flex>
      <Container>
        <Button onClick={handleOnClick}>Cick</Button>
        <Button onClick={handleUpload}>Upload</Button>
        <Button onClick={handleViewFile}>View</Button>
        <Button onClick={handleSign}>Sign</Button>
        <Button onClick={handleVerify}>verify</Button>
        <Button onClick={handleRequest}>handleRequest</Button>
        <label htmlFor="file-upload" className="file-upload-label">
          Choose a file to upload
        </label>
        <input
          id="file-upload"
          type="file"
          onChange={handleFileChange}
          style={{ display: "none" }}
        />
        <Container
          mt="5"
          pt="2"
          px="4"
          style={{ background: "var(--gray-a2)", minHeight: 500 }}
        >
          <img src={imageSrc} />
          {reclaimUrl && (
            <div
              style={{
                height: "auto",
                margin: "0 auto",
                maxWidth: 64,
                width: "100%",
              }}
            >
              <QRCode
                size={500}
                style={{ height: "auto", maxWidth: "100%", width: "100%" }}
                value={reclaimUrl}
                viewBox={`0 0 256 256`}
              />
            </div>
          )}
        </Container>
      </Container>
    </>
  );
}

export default App;
