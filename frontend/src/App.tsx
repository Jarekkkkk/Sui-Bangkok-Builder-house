import {
  ConnectButton,
  useCurrentAccount,
  useSignTransaction,
  useSuiClient,
} from "@mysten/dapp-kit";
import { Box, Button, Container, Flex, Heading } from "@radix-ui/themes";
import { Transaction } from "@mysten/sui/transactions";
import {
  getSentTransactionsWithLinks,
  ZkSendLinkBuilder,
} from "@mysten/zksend";
import { SUI_TYPE_ARG } from "@mysten/sui/utils";
import { ChangeEvent, useState } from "react";
import { WALRUS_AGGREGATOR, WALRUS_PUBLISHER } from "./lib/constant";
import { fileToBlob, streamToBlob } from "./lib/util";

function App() {
  const suiClient = useSuiClient();
  const { mutateAsync: signTransaction } = useSignTransaction();
  const account = useCurrentAccount();
  const [file, setFile] = useState<File>();
  const [imageSrc, setImageSrc] = useState<string>();
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
        `${WALRUS_AGGREGATOR}/v1/ZzT11eXNtqnEtj9qo12TNoQxCS0Ptt0v1qm7IgSLtlY`,
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
        </Container>
      </Container>
    </>
  );
}

export default App;
