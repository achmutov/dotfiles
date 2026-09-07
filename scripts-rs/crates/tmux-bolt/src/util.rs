#[macro_export]
macro_rules! impl_from_enum {
    ($enum_name:ident::$enum_variant:ident, $inner:ty) => {
        impl From<$inner> for $enum_name {
            fn from(value: $inner) -> Self {
                Self::$enum_variant(value)
            }
        }
    };
}
