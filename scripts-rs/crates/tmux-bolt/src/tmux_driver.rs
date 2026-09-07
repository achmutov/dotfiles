use crate::types;
use std::io;
use std::process::Command;

pub const PANE_FORMAT: &str = "#{pane_id}:#{pane_left}:#{pane_top}:#{pane_width}:#{pane_height}:#{scroll_position}:#{pane_mode}";

fn cmd() -> Command {
    Command::new("tmux")
}

fn exec(
    command: &mut Command,
    fail_reason: &'static str,
) -> Result<std::process::Output, types::TmuxError> {
    let output = command.output()?;
    if output.status.success() {
        Ok(output)
    } else {
        Err(types::TmuxError::Execution(output, fail_reason))
    }
}

/// If the window is zoomed (Z flag in window_flags on each pane), then return only active pane.
/// Otherwise, returns all window panes.
///
/// * `window`: source window
pub fn list_panes(window: &str) -> Result<Vec<types::PaneBase>, types::TmuxError> {
    let output = exec(
        cmd().args([
            "list-panes",
            "-t",
            window,
            "-F",
            PANE_FORMAT,
            "-f",
            // if zoom flag is set, then require only active pane
            "#{?#{m:*Z*,#{window_flags}},#{pane_active},1}",
        ]),
        "list panes",
    )?;

    let mut panes = Vec::with_capacity(6);
    let tmux_stdout = String::from_utf8_lossy(&output.stdout);
    for line in tmux_stdout.lines() {
        let pane = match parse_pane(line) {
            Ok(pane) => pane,
            Err(kind) => {
                return Err(types::TmuxError::Parse(types::TmuxParseError {
                    kind,
                    line: line.into(),
                }));
            }
        };
        panes.push(pane);
    }
    Ok(panes)
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
                    .map_err(|_| types::ParsePaneErrorKind::ParseInt)?,
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

/// Freezes panes without mode and captures output from no-mode, copy-mode, select-mode panes.
pub fn freeze_and_capture_panes(
    panes: Vec<types::PaneBase>,
) -> Result<Vec<types::Pane>, types::TmuxError> {
    // Freeze command
    let mut first_cmd = {
        let mut first_cmd = cmd();
        panes
            .iter()
            .filter(|pane| matches!(pane.mode, types::PaneMode::Empty))
            .for_each(|pane| {
                first_cmd.args(["copy-mode", "-t", &pane.id, ";"]);
            });
        Some(first_cmd)
    };

    let mut panes_out = Vec::with_capacity(panes.len());
    for pane in &panes {
        let mut current_cmd = first_cmd.take().unwrap_or(cmd());
        let navigable = match pane.mode {
            types::PaneMode::Seekable { scroll } => {
                let scroll = scroll as i64;
                let height = pane.dim.height as i64;
                current_cmd.args([
                    "capture-pane",
                    "-p",
                    "-N",
                    "-t",
                    &pane.id,
                    "-S",
                    &(-scroll).to_string(),
                    "-E",
                    &(-(scroll - height + 1)).to_string(),
                ]);
                true
            }
            types::PaneMode::Empty | types::PaneMode::Other => {
                current_cmd.args(["capture-pane", "-p", "-N", "-t", &pane.id]);
                false
            }
        };
        let output = exec(&mut current_cmd, "capture panes").inspect_err(|_| {
            _ = unfreeze_panes(panes.iter(), "");
        })?;
        panes_out.push(types::Pane {
            // TODO: remove redundant allocation
            base: pane.clone(),
            content: String::from_utf8_lossy(&output.stdout).into(),
            navigable,
        });
    }

    Ok(panes_out)
}

pub fn switch_to_window_by_pane(pane: &str) -> Result<(), types::TmuxError> {
    // query window id
    let output = exec(
        cmd().args(["display-message", "-p", "-t", pane, "#{window_id}"]),
        "query window",
    )?;

    // retrieve id
    let window_id_output = String::from_utf8_lossy(&output.stdout);
    let window_id = window_id_output.trim();

    // switch to window
    exec(
        cmd().args(["select-window", "-t", window_id]),
        "select window",
    )?;

    Ok(())
}

// maybe unfreezing should ignore when pane is not found?
pub fn unfreeze_panes<'a>(
    panes: impl Iterator<Item = &'a types::PaneBase>,
    chosen_pane_id: &str,
) -> Result<(), types::TmuxError> {
    let mut current_cmd = cmd();
    let mut has_commands = false;
    panes
        // Don't change the chosen pane
        .filter(|pane| pane.id != chosen_pane_id)
        // Change only those without modes prior
        .filter(|pane| matches!(pane.mode, types::PaneMode::Empty))
        .for_each(|pane| {
            if has_commands {
                current_cmd.arg(";");
            }
            current_cmd.args(["send-keys", "-X", "-t", &pane.id, "cancel"]);
            has_commands = true;
        });

    if !has_commands {
        return Ok(());
    }

    exec(&mut current_cmd, "unfreeze panes")?;
    Ok(())
}
