#!/usr/bin/env -S cargo +nightly -Zscript -q
---
[package]
name = "ts2chap"
version = "0.1.0"
edition = "2024"

[dependencies]
chrono = "0.4.42"

[profile.dev]
opt-level = 3
debug = false
strip = true
lto = true
incremental = false
codegen-units = 1
---

use std::io::{self, Write};

enum AppError {
    #[allow(dead_code)]
    Io(io::Error),
    #[allow(dead_code)]
    Parse(chrono::ParseError, String),
}

impl From<io::Error> for AppError {
    fn from(value: io::Error) -> Self {
        AppError::Io(value)
    }
}

impl std::fmt::Debug for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(err) => err.fmt(f),
            Self::Parse(err, chap) => f.write_fmt(format_args!("Failed to parse '{chap}': {err:?}")),
        }
    }
}

fn main() -> Result<(), AppError> {
    let path = {
        let mut args = std::env::args();
        let cmd = args.next().unwrap();
        match args.next() {
            Some(path) => path,
            None => {
                eprintln!("usage: {cmd} <PATH>");
                eprintln!("ffmpeg -i input_video.mp4 -i chapters.ffmetadata -map_metadata 1 -c:v copy -c:a copy -y output_video.mp4");
                eprintln!("ffprobe -hide_banner -i input_video.mp4 -print_format json -show_chapters");
                return Ok(());
            }
        }
    };

    let content = std::fs::read_to_string(path)?;
    let base_time = chrono::NaiveTime::from_hms_opt(0, 0, 0).unwrap();
    let mut print_lock = io::stdout().lock();

    // Parse START and TITLE
    let mut chapter_entries = content
        .lines()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| {
            let (ts, title) = match s.split_once(' ') {
                Some((ts, title)) => (ts, Some(title)),
                None => (s, None),
            };

            let ts = chrono::NaiveTime::parse_from_str(ts, "%H:%M:%S")
                .map(|start| (start - base_time).num_milliseconds());

            (ts, title)
        })
        .peekable();

    // Lookahead for END
    let chapters = std::iter::from_fn(|| {
        let (maybe_start, title) = chapter_entries.next()?;
        let maybe_end = chapter_entries.peek()
            .map(|(maybe_end, _)| maybe_end)
            // None = Last chapter
            .unwrap_or(&Ok(i64::MAX));
        Some((title, maybe_start, *maybe_end))
    });

    // Collect and print output
    writeln!(print_lock, ";FFMETADATA1")?;
    chapters.enumerate().try_for_each(|(i, (title, maybe_start, maybe_end))| {
        let title = match title {
            Some(s) => s.into(),
            None => format!("Chapter {i}"),
        };

        // For some reason, ? can't infer title can be moved, so verbosely return
        let start = match maybe_start {
            Ok(start) => start,
            Err(err) => return Err(AppError::Parse(err, title)),
        };
        let end = match maybe_end {
            Ok(start) => start,
            Err(err) => return Err(AppError::Parse(err, title)),
        };

        writeln!(print_lock, "[CHAPTER]")?;
        writeln!(print_lock, "TIMEBASE=1/1000")?;
        writeln!(print_lock, "START={start}")?;
        writeln!(print_lock, "END={end}")?;
        writeln!(print_lock, "TITLE={title}")?;
        Ok::<(), AppError>(())
    })?;

    Ok(())
}
