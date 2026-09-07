mod tmux_driver;
mod types;
mod util;

use crossterm::ExecutableCommand;
use std::io::{self, Write};
use std::process::ExitCode;

use crate::types::TmuxError;

#[derive(Debug)]
enum AppError {
    /// Failed to parse line
    Tmux(types::TmuxError),
    #[allow(dead_code)]
    Io(io::Error),
}

impl_from_enum! {AppError::Io, io::Error}
impl_from_enum! {AppError::Tmux, types::TmuxError}

fn draw_panes(panes: &[types::Pane]) -> io::Result<()> {
    let mut stdout = std::io::stdout();
    for pane in panes {
        // content
        for (i, line) in pane.content.lines().enumerate() {
            crossterm::queue!(
                stdout,
                crossterm::cursor::MoveTo(pane.base.dim.left, pane.base.dim.top + i as u16,),
                crossterm::style::Print(line),
            )?;
        }

        // vertical
        if pane.base.dim.left > 0 {
            for i in 0..=pane.base.dim.height {
                crossterm::queue!(
                    stdout,
                    crossterm::cursor::MoveTo(pane.base.dim.left - 1, pane.base.dim.top + i,),
                    crossterm::style::Print('│')
                )?;
            }
        }
        if pane.base.dim.top > 0 {
            for i in 0..pane.base.dim.width {
                crossterm::queue!(
                    stdout,
                    crossterm::cursor::MoveTo(pane.base.dim.left + i, pane.base.dim.top - 1,),
                    crossterm::style::Print('─')
                )?;
            }
        }
    }
    stdout.flush()?;
    Ok(())
}

fn run(source_window: &str, tmux_bolt_pane: &str) -> Result<(), AppError> {
    let panes_base = tmux_driver::list_panes(source_window)?;
    let panes = tmux_driver::freeze_and_capture_panes(panes_base)?;

    draw_panes(&panes)
        .map_err(AppError::Io)
        .and_then(|_| tmux_driver::switch_to_window_by_pane(tmux_bolt_pane).map_err(AppError::Tmux))
        .and_then(|_| crossterm::event::read().map_err(AppError::Io))
        .inspect_err(|_| {
            _ = tmux_driver::unfreeze_panes(panes.iter().map(|pane| &pane.base), "");
        })?;

    tmux_driver::unfreeze_panes(panes.iter().map(|pane| &pane.base), "")?;

    Ok(())
}

struct TerminalGuard;
impl TerminalGuard {
    fn try_new() -> io::Result<Self> {
        crossterm::terminal::enable_raw_mode()?;
        let guard = Self; // avoid redundant disable_raw_mode on enable_raw_mode error
        crossterm::execute!(io::stdout(), crossterm::cursor::Hide)?;
        Ok(guard)
    }
}
impl Drop for TerminalGuard {
    fn drop(&mut self) {
        _ = io::stdout().execute(crossterm::cursor::Show);
        _ = crossterm::terminal::disable_raw_mode();
    }
}

struct TerminalGuardError;
impl TerminalGuardError {
    fn new() -> Self {
        _ = crossterm::execute!(
            std::io::stdout(),
            crossterm::terminal::Clear(crossterm::terminal::ClearType::All)
        );
        _ = crossterm::execute!(std::io::stderr(), crossterm::cursor::MoveTo(0, 0),);
        Self
    }
}
impl Drop for TerminalGuardError {
    fn drop(&mut self) {
        _ = crossterm::terminal::enable_raw_mode();
        _ = crossterm::event::read();
        _ = crossterm::terminal::disable_raw_mode();
    }
}

fn report_tmux_error_reason(output: &std::process::Output, reason: &str) {
    eprintln!(
        "Tmux failed: {reason}

Tmux stdout:
-----------
{}
-----------

Tmux stderr:
-----------
{}
-----------
",
        String::from_utf8_lossy(&output.stdout).trim(),
        String::from_utf8_lossy(&output.stderr).trim(),
    );
}

fn main() -> ExitCode {
    let source_window = {
        let mut args = std::env::args();
        let program = args.next();
        match args.next() {
            Some(window) => window,
            None => {
                let program = program.expect("Couldn't get the executable name");
                eprintln!("usage: {program} TMUX_WINDOW_ID");
                return 64.into(); // CLI error
            }
        }
    };

    let tmux_bolt_pane = match std::env::var("TMUX_PANE") {
        Ok(var) => var,
        Err(err) => {
            eprintln!("{err}");
            return ExitCode::FAILURE;
        }
    };

    // TODO: we probably don't even need this guard anymore
    let _terminal_guard = TerminalGuard::try_new();
    let result = match _terminal_guard {
        Ok(_guard) => run(&source_window, &tmux_bolt_pane),
        Err(err) => Err(AppError::Io(err)),
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            let _terminal_guard_error = TerminalGuardError::new();
            match err {
                AppError::Tmux(TmuxError::Execution(output, reason)) => {
                    report_tmux_error_reason(&output, reason);
                    match output.status.code() {
                        Some(code) => {
                            eprintln!("Tmux exited with status {code}");
                            (code as u8).into() // Unix specific
                        }
                        None => {
                            eprintln!("Tmux exited unexpectedly");
                            ExitCode::FAILURE
                        }
                    }
                }
                AppError::Tmux(TmuxError::Parse(types::TmuxParseError { line, kind })) => {
                    eprintln!("Couldn't parse tmux output");
                    match kind {
                        types::ParsePaneErrorKind::MissingAttribute => {
                            eprintln!("Missing attribute")
                        }
                        types::ParsePaneErrorKind::ParseInt => eprintln!("Failed to parse integer"),
                        types::ParsePaneErrorKind::MissingScrollPosition => {
                            eprintln!("Missing scroll position")
                        }
                    };
                    eprintln!("Received line: {line}");
                    eprintln!("Tmux format:   {}", tmux_driver::PANE_FORMAT);
                    ExitCode::FAILURE
                }
                err => {
                    // AppError::Io | AppError(TmuxError::Io)
                    eprintln!("{err:#?}");
                    74.into() // input/output
                }
            }
        }
    }
}
