module sui_sign::sui_sign{
    use sui::sui::SUI;
    use sui::coin::Coin;

    use walrus::blob::Blob;

    public struct Document has key {
        id: UID,
        sender: address
        blob: Blob,
        gas: Coin<SUI>
    }

    public fun wrap(blob: Blob, ctx: &mut TxContext): WrappedBlob {
        WrappedBlob { id: object::new(ctx), blob }
    }
}
