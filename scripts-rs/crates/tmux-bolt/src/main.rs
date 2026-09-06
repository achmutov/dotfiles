use std::process::exit;

mod tmux_driver;
mod types;

use crossterm::QueueableCommand;
use std::io::{self, Write};

fn main() -> io::Result<()> {
    let mut args = std::env::args();
    let window = {
        let program = args.next();
        args.next().unwrap_or_else(|| {
            let program = program.expect("Couldn't get the executable name");
            eprintln!("usage: {program} TMUX_WINDOW_ID");
            exit(1);
        })
    };

    let mut stdout = io::stdout();

    crossterm::terminal::enable_raw_mode()?;
    stdout
        .queue(crossterm::cursor::Hide)?
        .queue(crossterm::terminal::Clear(
            crossterm::terminal::ClearType::All,
        ))?;
    stdout.flush()?;

    for line in tmux_driver::list_panes(&window)?.lines() {
        let pane = match tmux_driver::parse_pane(line) {
            Ok(pane) => pane,
            Err(kind) => {
                stdout.queue(crossterm::cursor::Show)?;
                crossterm::terminal::disable_raw_mode()?;
                match kind {
                    types::ParsePaneErrorKind::MissingAttribute => eprintln!("Missing attribute"),
                    types::ParsePaneErrorKind::ParseInt => eprintln!("Failed to parse integer"),
                    types::ParsePaneErrorKind::MissingScrollPosition => {
                        eprintln!("Missing scroll position")
                    }
                };
                eprintln!("Received line: {line}");
                eprintln!("Tmux format:   {}", tmux_driver::PANE_FORMAT);
                crossterm::event::read().unwrap();
                exit(1);
            }
        };

        let (content, _navigable) = match pane.mode {
            types::PaneMode::Seekable { scroll } => (
                tmux_driver::capture_pane_scroll(&pane.id, scroll, pane.dim.height)?,
                true,
            ),
            types::PaneMode::Empty | types::PaneMode::Other => {
                (tmux_driver::capture_pane_regular(&pane.id)?, false)
            }
        };

        for (i, line) in content.lines().enumerate() {
            stdout
                .queue(crossterm::cursor::MoveTo(
                    pane.dim.left,
                    pane.dim.top + i as u16,
                ))?
                .queue(crossterm::style::Print(line))?;
        }

        // vertical
        if pane.dim.left > 0 {
            for i in 0..=pane.dim.height {
                stdout
                    .queue(crossterm::cursor::MoveTo(
                        pane.dim.left - 1,
                        pane.dim.top + i,
                    ))?
                    .queue(crossterm::style::Print('│'))?;
            }
        }
        if pane.dim.top > 0 {
            for i in 0..pane.dim.width {
                stdout
                    .queue(crossterm::cursor::MoveTo(
                        pane.dim.left + i,
                        pane.dim.top - 1,
                    ))?
                    .queue(crossterm::style::Print('─'))?;
            }
        }
    }
    stdout.flush()?;

    crossterm::event::read()?;
    stdout.queue(crossterm::cursor::Show)?;
    crossterm::terminal::disable_raw_mode()?;

    Ok(())
}
