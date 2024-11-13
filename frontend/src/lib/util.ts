export async function streamToBlob(
  readableStream: ReadableStream<Uint8Array> | null,
) {
  if (!readableStream) return null;
  const reader = readableStream.getReader();
  const chunks = [];
  let done, value;

  while (!done) {
    ({ done, value } = await reader.read());
    if (value) {
      chunks.push(value);
    }
  }

  console.log("chunks", chunks);

  return new Blob(chunks, { type: "image/png" });
}

export function fileToBlob(file: File) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      if (!reader.result) {
        reject(new Error("NO Reader result"));
      } else {
        const blob = new Blob([reader.result], { type: file.type });
        resolve(blob);
      }
    };
    reader.onerror = reject;
    reader.readAsArrayBuffer(file);
  });
}
