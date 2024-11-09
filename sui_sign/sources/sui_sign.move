module sui_sign::sui_sign{
    use walrus::blob::Blob;

    public struct WrappedBlob has key {
        id: UID,
        blob: Blob,
    }

    public fun wrap(blob: Blob, ctx: &mut TxContext): WrappedBlob {
        WrappedBlob { id: object::new(ctx), blob }
    }
}
