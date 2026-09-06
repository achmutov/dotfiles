use crate::types;
use std::io;
use std::process::Command;

pub const PANE_FORMAT: &str = "#{pane_id}:#{pane_left}:#{pane_top}:#{pane_width}:#{pane_height}:#{scroll_position}:#{pane_mode}";

#[inline]
fn cmd() -> Command {
    Command::new("tmux")
}

/// If the window is zoomed (Z flag in window_flags on each pane), then return only active pane.
/// Otherwise, returns all window panes.
///
/// * `window`: source window
pub fn list_panes(window: &str) -> io::Result<String> {
    let full_args = [
        "list-panes",
        "-t",
        window,
        "-F",
        PANE_FORMAT,
        "-f",
        // if zoom flag is set, then require only active pane
        "#{?#{m:*Z*,#{window_flags}},#{pane_active},1}",
    ];

    let output = cmd().args(full_args).output()?;
    Ok(String::from_utf8_lossy(&output.stdout).into())
}

pub fn parse_pane(line: &str) -> Result<types::PaneBase, types::ParsePaneErrorKind> {
    let mut split = line.split(':');
    let id = split
        .next()
        .ok_or(types::ParsePaneErrorKind::MissingAttribute)?
        .into();
    let mut parse_int = || {
        split
            .next()
            .ok_or(types::ParsePaneErrorKind::MissingAttribute)?
            .parse()
            .map_err(|_| types::ParsePaneErrorKind::ParseInt)
    };
    let left = parse_int()?;
    let top = parse_int()?;
    let width = parse_int()?;
    let height = parse_int()?;
    let scroll_position_str = split
        .next()
        .ok_or(types::ParsePaneErrorKind::MissingAttribute)?;
    let mode = match split
        .next()
        .ok_or(types::ParsePaneErrorKind::MissingAttribute)?
    {
        "copy-mode" | "view-mode" => match scroll_position_str {
            "" => return Err(types::ParsePaneErrorKind::MissingScrollPosition),
            scroll => types::PaneMode::Seekable {
                scroll: scroll
                    .parse()
                    .or(Err(types::ParsePaneErrorKind::ParseInt))?,
            },
        },
        "" => types::PaneMode::Empty,
        _ => types::PaneMode::Other,
    };
    Ok(types::PaneBase {
        id,
        dim: types::PaneDim {
            left,
            top,
            height,
            width,
        },
        mode,
    })
}

pub fn capture_pane_scroll(id: &str, scroll: u32, height: u16) -> io::Result<String> {
    let scroll = scroll as i64;
    let height = height as i64;
    let output = cmd()
        .args([
            "capture-pane",
            "-p",
            "-N",
            "-t",
            id,
            "-S",
            &(-scroll).to_string(),
            "-E",
            &(-(scroll - height + 1)).to_string(),
        ])
        .output()?;
    Ok(String::from_utf8_lossy(&output.stdout).into())
}

pub fn capture_pane_regular(id: &str) -> io::Result<String> {
    let output = cmd()
        .args(["capture-pane", "-p", "-N", "-t", id])
        .output()?;
    Ok(String::from_utf8_lossy(&output.stdout).into())
}
