#[derive(Debug)]
pub struct PaneBase {
    pub id: String,
    pub dim: PaneDim,
    pub mode: PaneMode,
}

#[derive(Debug)]
pub enum PaneMode {
    Empty,
    Seekable { scroll: u32 },
    Other,
}

#[derive(Debug)]
pub struct PaneDim {
    pub left: u16,
    pub top: u16,
    pub width: u16,
    pub height: u16,
}

#[derive(Debug)]
pub enum ParsePaneErrorKind {
    MissingAttribute,
    ParseInt,
    MissingScrollPosition,
}
