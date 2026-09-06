use std::io::{self, Write};

type TS = u32;

#[derive(Clone)]
struct ChapErr<'a> {
    title: Option<&'a str>,
    ts: &'a str,
}

#[derive(Clone)]
struct ChapOk<'a> {
    title: Option<&'a str>,
    ts: TS,
}

enum AppError<'a> {
    Io(io::Error),
    Parse(ChapErr<'a>),
}

impl From<io::Error> for AppError<'_> {
    fn from(value: io::Error) -> Self {
        AppError::Io(value)
    }
}

impl<'a> From<ChapErr<'a>> for AppError<'a> {
    fn from(value: ChapErr<'a>) -> Self {
        AppError::Parse(value)
    }
}

impl std::fmt::Debug for AppError<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(err) => err.fmt(f),
            Self::Parse(ChapErr { title, ts }) => match title {
                Some(title) => {
                    writeln!(
                        f,
                        "Invalid timestamp in chapter '{title}': must be [H:]MM:SS, got '{ts}'"
                    )
                }
                None => writeln!(f, "Invalid timestamp: must be [H:]MM:SS, got '{ts}'"),
            },
        }
    }
}

fn main() {
    let path = {
        let mut args = std::env::args();
        let cmd = args.next().unwrap();
        match args.next() {
            Some(path) => path,
            None => {
                eprintln!("usage: {cmd} <PATH>");
                eprintln!(
                    "ffmpeg -i input_video.mp4 -i chapters.ffmetadata -map_metadata 1 -c:v copy -c:a copy -y output_video.mp4"
                );
                eprintln!(
                    "ffprobe -hide_banner -i input_video.mp4 -print_format json -show_chapters"
                );
                std::process::exit(1);
            }
        }
    };

    let Ok(content) = std::fs::read_to_string(&path) else {
        eprintln!("Couldn't open file {path}");
        std::process::exit(1);
    };

    // Parse START and TITLE
    let mut chapter_entries = content
        .lines()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| {
            // Allow empty title
            let (ts_str, title) = match s.split_once(' ') {
                Some((ts_str, title)) => (ts_str, Some(title)),
                None => (s, None),
            };

            let parse_ts: fn(&str) -> Option<TS> = |ts_str| {
                let mut ts_parts_iter = ts_str.rsplit(':');
                let ss_str = ts_parts_iter.next()?;
                let mm_str = ts_parts_iter.next()?;
                let hh_str = ts_parts_iter.next();
                let None = ts_parts_iter.next() else {
                    return None;
                };

                let parse_ss_ms = |s: &str| -> Option<TS> {
                    if (0..=2).contains(&s.len())
                        && s.bytes().all(|c| c.is_ascii_digit())
                        && let Ok(value) = s.parse()
                        && value < 60
                    {
                        Some(value)
                    } else {
                        None
                    }
                };

                let ss = parse_ss_ms(ss_str)?;
                let mm = parse_ss_ms(mm_str)?;

                let hh: TS = match hh_str {
                    Some(hh) if !hh.is_empty() && hh.bytes().all(|c| c.is_ascii_digit()) => {
                        hh.parse().ok()?
                    }
                    Some(_) => return None,
                    None => 0,
                };

                let milliseconds = hh
                    .checked_mul(60 * 60 * 1000)
                    .and_then(|x| x.checked_add(mm * 60 * 1000))
                    .and_then(|x| x.checked_add((ss + 1) * 1000))?;

                Some(milliseconds)
            };

            parse_ts(ts_str)
                .map(|ts| ChapOk { ts, title })
                .ok_or(ChapErr { ts: ts_str, title })
        })
        .peekable();

    // Collect and print output
    let mut print_lock = io::stdout().lock();
    writeln!(print_lock, ";FFMETADATA1")
        .map_err(AppError::Io)
        .and(
            std::iter::from_fn(|| {
                let current = chapter_entries.next()?;
                let next = chapter_entries.peek().cloned();
                Some((current, next))
            })
            .try_for_each(|(current, maybe_next)| {
                let ChapOk {
                    title: maybe_title,
                    ts: start,
                } = current?;

                let end = match maybe_next {
                    Some(next) => next?.ts,
                    None => TS::MAX - 1,
                };

                writeln!(print_lock, "[CHAPTER]")?;
                writeln!(print_lock, "TIMEBASE=1/1000")?;
                writeln!(print_lock, "START={}", start)?;
                writeln!(print_lock, "END={}", end + 1)?;
                if let Some(title) = maybe_title {
                    writeln!(print_lock, "TITLE={title}")?;
                }
                Ok(())
            }),
        )
        .unwrap_or_else(|err: AppError| println!("{err:?}"));
}
