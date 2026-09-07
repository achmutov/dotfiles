use crate::impl_from_enum;
use std::io;

#[derive(Debug, Clone)]
pub struct PaneBase {
    pub id: String,
    pub dim: PaneDim,
    pub mode: PaneMode,
}

#[derive(Debug, Clone)]
pub enum PaneMode {
    Empty,
    Seekable { scroll: u32 },
    Other,
}

#[derive(Debug, Clone)]
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

pub struct Pane {
    pub base: PaneBase,
    pub content: String,
    #[allow(dead_code)]
    pub navigable: bool,
}

#[derive(Debug)]
pub struct TmuxParseError {
    pub line: String,
    pub kind: ParsePaneErrorKind,
}

#[derive(Debug)]
pub enum TmuxError {
    Execution(std::process::Output, &'static str),
    Parse(TmuxParseError),
    #[allow(dead_code)]
    Io(io::Error),
}

impl_from_enum! {TmuxError::Io, io::Error}
